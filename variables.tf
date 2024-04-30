variable "aws_region" {
  description = "AWS region to launch our services"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_file_layer" {
  description = "S3 Bucket contenning our utilities"
  type        = string
  default     = "s3_bucket_file_layer"
}

variable "s3_key_file_layer" {
  description = "Key for our lambda layer file"
  type        = string
  default     = "s3_key_file_layer"
}

variable "s3_landing_zone" {
  description = "Landing S3 Bucket"
  type        = string
  default     = "example-trigger-lf-landing-zone"
}

variable "s3_clean_zone" {
  description = "Clean S3 Bucket"
  type        = string
  default     = "example-trigger-lf-clean-zone"
}
