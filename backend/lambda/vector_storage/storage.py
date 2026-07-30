import json

import boto3


class VectorStorageWriter:
    """
    Takes a batch of vector-storage SQS records — each one produced by
    document_ingest and holding a vector key, its embedding, and its
    document metadata — and writes the whole batch to the S3 Vectors index
    with a single PutVectors call.
    """

    def __init__(self, vector_bucket_name, vector_index_name, s3vectors_client=None):
        self.vector_bucket_name = vector_bucket_name
        self.vector_index_name = vector_index_name
        self.s3vectors = s3vectors_client or boto3.client("s3vectors")

    def put_batch(self, records):
        vectors = [self._to_vector(record) for record in records]

        self.s3vectors.put_vectors(
            vectorBucketName=self.vector_bucket_name,
            indexName=self.vector_index_name,
            vectors=vectors,
        )

    @staticmethod
    def _to_vector(record):
        message = json.loads(record["body"])
        return {
            "key": message["key"],
            "data": {"float32": message["vector"]},
            "metadata": message["metadata"],
        }
