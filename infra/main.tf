terraform {
  required_version = ">= 1.6.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.0" } }
}

provider "aws" { region = "ap-south-1" }

data "aws_availability_zones" "available" { state = "available" }

resource "aws_kms_key" "data" {
  description             = "MindBridge private-beta data encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_s3_bucket" "private_objects" { bucket_prefix = "mindbridge-private-beta-" }
resource "aws_s3_bucket_server_side_encryption_configuration" "private_objects" {
  bucket = aws_s3_bucket.private_objects.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "aws:kms" kms_master_key_id = aws_kms_key.data.arn } }
}
resource "aws_s3_bucket_public_access_block" "private_objects" {
  bucket = aws_s3_bucket.private_objects.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_secretsmanager_secret" "runtime" { name_prefix = "mindbridge/private-beta/runtime-" kms_key_id = aws_kms_key.data.arn }
resource "aws_ecs_cluster" "app" { name = "mindbridge-private-beta" }

# RDS, Redis, WAF, private subnet, task-definition, and load-balancer resources
# are intentionally parameterized in the next deployment milestone: applying
# them without approved VPC, domain, image, and compliance inputs is forbidden.
