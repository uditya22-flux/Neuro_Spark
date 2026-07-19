# AWS Mumbai foundation

This Terraform foundation targets `ap-south-1` and creates the network, KMS
keys, encrypted S3 bucket, RDS PostgreSQL, ElastiCache Redis, ECS/Fargate
cluster, WAF, and Secrets Manager placeholders required by the private beta.

Before applying, provide an approved AWS account, DNS/domain configuration,
container image URIs, VPC CIDRs, and production secret values. Keep ECS tasks
in private subnets; only the load balancer is public. Enable RDS deletion
protection and review backup retention with counsel before production.
