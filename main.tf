terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name          = "awsDataWrangler210_python38"
  description         = "AWS Data Wrangler, Version 2.10.0 for Python 3.8"
  compatible_runtimes = ["python3.8"]
  s3_bucket           = var.s3_bucket_file_layer
  s3_key              = var.s3_key_file_layer
  #filename = "awswrangler-layer-2.10.0-py3.8.zip"
}

resource "aws_s3_bucket" "s3_landing_zone" {
  bucket        = var.s3_landing_zone
  force_destroy = true

  tags = {
    Environment = "Test"
  }
}

resource "aws_s3_bucket" "s3_clean_zone" {
  bucket        = var.s3_clean_zone
  force_destroy = true

  tags = {
    Environment = "Test"
  }
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:CreateLogStream"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.s3_landing_zone}/*",
      "arn:aws:s3:::${var.s3_landing_zone}",
      "arn:aws:s3:::${var.s3_clean_zone}/*",
      "arn:aws:s3:::${var.s3_clean_zone}"
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    actions   = ["glue:*"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "iam_policy" {
  name        = "ExampleLambdaS3CWGluePolicy"
  description = "This policy will be used for read our source S3 Bucket (landing), Write to our target S3 Bucket (clean), Write logs to Amazon CloudWatch and Access to all Glue API actions"
  policy      = data.aws_iam_policy_document.policy.json

  tags = {
    Environment = "Test"
  }
}

resource "aws_iam_role" "iam_role" {
  name                = "ExampleLambdaS3CWGlueRole"
  assume_role_policy  = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [aws_iam_policy.iam_policy.arn]

  tags = {
    Environment = "Test"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "CSVtoParquetLambda.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "lambda_function" {
  function_name    = "CSVtoParquetLambda"
  role             = aws_iam_role.iam_role.arn
  description      = "This will be triggered whenever a CSV file is uploaded to our source S3 bucket. The uploaded CSV file will be converted to Parquet, written out to the target bucket, and added to the Glue catalog using AWS Data Wrangler"
  runtime          = "python3.8"
  filename         = "lambda_function_payload.zip"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  handler          = "CSVtoParquetLambda.lambda_handler"
  timeout          = 60

  environment {
    variables = {
      OUTPUT_BUCKET = var.s3_clean_zone
    }
  }

  tags = {
    Environment = "Test"
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_landing_zone.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.s3_landing_zone.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}