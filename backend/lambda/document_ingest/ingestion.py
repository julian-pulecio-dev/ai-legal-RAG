import json
import math
import re

import boto3

# S3 Vectors (PutInputVector.key) constraints: 1-1024 bytes, no character
# pattern documented by AWS. We enforce a conservative safelist ourselves
# so the S3 object key can be used as the vector key as-is (minus the
# ".json" suffix) and stay traceable back to its source file.
# https://docs.aws.amazon.com/AmazonS3/latest/API/API_S3VectorBuckets_PutInputVector.html
_MAX_VECTOR_KEY_BYTES = 1024
_VECTOR_KEY_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9/_.-]*$")

# S3 Vectors metadata constraints (filterable metadata, i.e. metadata that
# isn't listed as non-filterable on the index — which is our case, since
# the index doesn't configure any non-filterable keys).
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-vectors-limitations.html
_MAX_METADATA_KEYS = 50
_MAX_FILTERABLE_METADATA_BYTES = 2048


class DocumentEmbedder:
    """
    Validates a document_ingest SQS record (an S3 "Object Created" event
    forwarded through EventBridge), fetches the referenced chunk JSON file
    from S3, embeds its text with Bedrock Titan, and forwards the resulting
    vector + document metadata to the vector-storage SQS queue for the
    vector_storage Lambda to write into S3 Vectors with PutVectors.

    The chunk file is expected to already be reviewed/approved text, one
    JSON object per file:
        {
          "schema_version": "1",
          "text": "...",
          "document_metadata": {
            "title": "...",
            "document_type": "...",
            "upload_date": "2026-07-29",
            "language": "es"
          }
        }

    document_metadata.source_uri is not read from the file — it's derived
    from the triggering S3 event's own bucket/key ("s3://{bucket}/{key}"),
    which is the authoritative location of the document, and overwrites
    whatever the file might contain under that field.

    The S3 object key (minus ".json") is used as the vector's key in S3
    Vectors, so it must satisfy S3 Vectors' own constraints on that field —
    validated here, before spending a Bedrock call on a file that would be
    rejected downstream anyway.
    """

    def __init__(
        self,
        bucket_name,
        embedding_model_id,
        embedding_dimension,
        vector_storage_queue_url,
        s3_client=None,
        bedrock_client=None,
        sqs_client=None,
    ):
        self.bucket_name = bucket_name
        self.embedding_model_id = embedding_model_id
        self.embedding_dimension = embedding_dimension
        self.vector_storage_queue_url = vector_storage_queue_url
        self.s3 = s3_client or boto3.client("s3")
        self.bedrock = bedrock_client or boto3.client("bedrock-runtime")
        self.sqs = sqs_client or boto3.client("sqs")

    def process_record(self, record):
        bucket, key, vector_key = self._validate_event(record)
        chunk = self._load_chunk(key)

        document_metadata = chunk["document_metadata"]
        document_metadata["source_uri"] = f"s3://{bucket}/{key}"
        self._validate_metadata(document_metadata, key)

        vector = self._embed(chunk["text"])
        self._validate_vector(vector, record["messageId"])
        self._enqueue(vector_key, document_metadata, vector)
        return key

    def _validate_event(self, record):
        try:
            detail = json.loads(record["body"])["detail"]
            bucket = detail["bucket"]["name"]
            key = detail["object"]["key"]
        except (KeyError, TypeError, ValueError) as e:
            raise ValueError(
                f"Malformed S3 event in record {record['messageId']}: {e}"
            ) from e

        if bucket != self.bucket_name:
            raise ValueError(
                f"Unexpected bucket '{bucket}' in record {record['messageId']} "
                f"(expected '{self.bucket_name}')"
            )

        if not key or key.endswith("/"):
            raise ValueError(f"Not a document key: '{key}' in record {record['messageId']}")

        if not key.lower().endswith(".json"):
            raise ValueError(f"Not a chunk file: '{key}' in record {record['messageId']}")

        vector_key = key[: -len(".json")]
        self._validate_vector_key(vector_key, record["messageId"])

        return bucket, key, vector_key

    def _validate_vector_key(self, vector_key, message_id):
        encoded_length = len(vector_key.encode("utf-8"))
        if not 1 <= encoded_length <= _MAX_VECTOR_KEY_BYTES:
            raise ValueError(
                f"Vector key '{vector_key}' (record {message_id}) is {encoded_length} bytes; "
                f"S3 Vectors requires between 1 and {_MAX_VECTOR_KEY_BYTES} bytes"
            )

        if not _VECTOR_KEY_PATTERN.match(vector_key):
            raise ValueError(
                f"Vector key '{vector_key}' (record {message_id}) contains characters outside "
                f"the allowed set [A-Za-z0-9/_.-]; rename the file to a valid key"
            )

    def _load_chunk(self, key):
        response = self.s3.get_object(Bucket=self.bucket_name, Key=key)
        chunk = json.loads(response["Body"].read())

        for field in ("text", "document_metadata"):
            if field not in chunk:
                raise ValueError(f"Chunk '{key}' is missing required field '{field}'")

        return chunk

    def _validate_metadata(self, document_metadata, key):
        if len(document_metadata) > _MAX_METADATA_KEYS:
            raise ValueError(
                f"Chunk '{key}' has {len(document_metadata)} document_metadata keys; "
                f"S3 Vectors allows at most {_MAX_METADATA_KEYS}"
            )

        encoded_size = len(json.dumps(document_metadata).encode("utf-8"))
        if encoded_size > _MAX_FILTERABLE_METADATA_BYTES:
            raise ValueError(
                f"Chunk '{key}' document_metadata is {encoded_size} bytes; "
                f"S3 Vectors allows at most {_MAX_FILTERABLE_METADATA_BYTES} bytes of "
                f"filterable metadata per vector"
            )

    def _embed(self, text):
        response = self.bedrock.invoke_model(
            modelId=self.embedding_model_id,
            body=json.dumps(
                {
                    "inputText": text,
                    "dimensions": self.embedding_dimension,
                    "normalize": True,
                }
            ),
        )
        return json.loads(response["body"].read())["embedding"]

    def _validate_vector(self, vector, message_id):
        # S3 Vectors requires finite floating-point values, and disallows
        # all-zero vectors under the cosine distance metric used by our
        # index.
        if not all(math.isfinite(v) for v in vector):
            raise ValueError(f"Embedding for record {message_id} contains NaN/Infinity values")

        if all(v == 0 for v in vector):
            raise ValueError(
                f"Embedding for record {message_id} is an all-zero vector, not allowed "
                f"with the cosine distance metric"
            )

    def _enqueue(self, vector_key, document_metadata, vector):
        self.sqs.send_message(
            QueueUrl=self.vector_storage_queue_url,
            MessageBody=json.dumps(
                {
                    "key": vector_key,
                    "vector": vector,
                    "metadata": document_metadata,
                }
            ),
        )
