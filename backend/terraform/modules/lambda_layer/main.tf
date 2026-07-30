# Module "lambda_layer": packages a directory into a Lambda layer .zip and
# publishes it. source_dir must contain a top-level "python/" folder, which
# is what makes its contents importable at runtime (extracted to
# /opt/python, already on sys.path for the Python runtimes).

data "archive_file" "this" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/.build/${var.name}-layer.zip"
}

resource "aws_lambda_layer_version" "this" {
  layer_name          = var.name
  filename            = data.archive_file.this.output_path
  source_code_hash    = data.archive_file.this.output_base64sha256
  compatible_runtimes = var.compatible_runtimes
}
