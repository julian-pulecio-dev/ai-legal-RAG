# Module "lambda_package": packages a Lambda function's source code into a
# .zip and exposes its hash, so any Lambda module (current or future) can
# recreate it just by running `terraform apply` when the code changes.

data "archive_file" "this" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.root}/.build/${var.name}.zip"
}
