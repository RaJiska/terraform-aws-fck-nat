########################################################################
# VPC Flow Logs -> S3 (parquet, hive-partitioned) with optional Athena #
########################################################################

resource "aws_s3_bucket" "flow_logs" {
  #checkov:skip=CKV_AWS_144:Cross-region replication is not needed for flow logs and would double storage cost.
  #checkov:skip=CKV2_AWS_62:Event notifications are not needed for a log-only bucket with no downstream processing.
  #checkov:skip=CKV_AWS_18:Access logging is intentionally omitted to avoid recursive logging on a bucket that itself receives log deliveries.
  #checkov:skip=CKV_AWS_145:Deliberately using SSE-S3 instead of a customer-managed KMS key to avoid the $1/month CMK charge for this low-sensitivity operational log data.
  bucket = local.vpc_flow_logs_name
  tags   = merge(local.common_tags, { Name = local.vpc_flow_logs_name })
}

resource "aws_s3_bucket_versioning" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enforce bucket-owner-only object ownership; disables ACLs entirely (modern best practice)
resource "aws_s3_bucket_ownership_controls" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Lifecycle policy to archive/delete old logs (cost control)
resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  rule {
    id     = "archive-old-logs"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA" # cheaper after 30 days
    }

    transition {
      days          = 90
      storage_class = "GLACIER" # cheapest for long-term retention
    }

    expiration {
      days = 365 # delete after 1 year
    }

    noncurrent_version_expiration {
      noncurrent_days = 30 # clean up old versions quickly, flow log objects are never intentionally overwritten
    }
  }
}

# Block public access (security)
resource "aws_s3_bucket_public_access_block" "flow_logs" {
  bucket                  = aws_s3_bucket.flow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket encryption (SSE-S3: no customer-managed KMS key needed/billed for this
# low-sensitivity operational log data; AWS manages the key at no extra cost)
resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowVPCFlowLogsDelivery"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.flow_logs.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
            "s3:x-amz-acl"      = "bucket-owner-full-control"
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:ec2:${local.region}:${local.account_id}:*"
          }
        }
      },
      {
        Sid    = "AllowLogServiceToReadBucket"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.flow_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:ec2:${local.region}:${local.account_id}:*"
          }
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# VPC Flow Log
#
# A single VPC-level flow log (rather than one per subnet) keeps the resource
# count low and delivers to S3 in parquet format with hive-style (key=value)
# partitioning by hour. Parquet is columnar/compressed, which significantly
# reduces both S3 storage cost and the amount of data scanned (and therefore
# billed) per Athena query compared to the default gzip'd text format.
#
# No IAM role is configured: iam_role_arn is only used when the destination
# is CloudWatch Logs or Kinesis Data Firehose. For an S3 destination, delivery
# is authorized purely via the bucket policy above.
# ---------------------------------------------------------------------------
resource "aws_flow_log" "main" {
  log_destination_type     = "s3"
  log_destination          = aws_s3_bucket.flow_logs.arn
  traffic_type             = "REJECT" # only reject traffic, reduces volume/cost vs ALL
  max_aggregation_interval = 600      # 10 minutes, reduces delivery frequency/cost vs 60s

  vpc_id = aws_vpc.main.id

  destination_options {
    file_format                = "parquet"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }

  depends_on = [
    aws_s3_bucket_policy.flow_logs,
    aws_s3_bucket_public_access_block.flow_logs,
    aws_s3_bucket_ownership_controls.flow_logs,
  ]


  tags = merge(local.common_tags, { Name = local.vpc_flow_logs_name })
}

# ---------------------------------------------------------------------------
# Optional: Glue Catalog Database + Table for querying flow logs via Athena
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_database" "flow_logs" {
  count = var.enable_athena ? 1 : 0

  name        = replace(local.vpc_flow_logs_name, "-", "_")
  description = "Glue database for querying ${local.vpc_flow_logs_name} VPC flow logs"
}

resource "aws_glue_catalog_table" "flow_logs" {
  count = var.enable_athena ? 1 : 0

  name          = "vpc_flow_logs"
  database_name = aws_glue_catalog_database.flow_logs[0].name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    classification              = "parquet"
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2023,2100"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "projection.month.digits"   = "2"
    "projection.day.type"       = "integer"
    "projection.day.range"      = "1,31"
    "projection.day.digits"     = "2"
    "projection.hour.type"      = "integer"
    "projection.hour.range"     = "0,23"
    "projection.hour.digits"    = "2"
    "storage.location.template" = "s3://${aws_s3_bucket.flow_logs.bucket}/AWSLogs/aws-account-id=${local.account_id}/aws-service=vpcflowlogs/aws-region=${local.region}/year=$${year}/month=$${month}/day=$${day}/hour=$${hour}/"
  }

  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
  partition_keys {
    name = "hour"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.flow_logs.bucket}/AWSLogs/aws-account-id=${local.account_id}/aws-service=vpcflowlogs/aws-region=${local.region}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "version"
      type = "int"
    }
    columns {
      name = "account_id"
      type = "string"
    }
    columns {
      name = "interface_id"
      type = "string"
    }
    columns {
      name = "srcaddr"
      type = "string"
    }
    columns {
      name = "dstaddr"
      type = "string"
    }
    columns {
      name = "srcport"
      type = "int"
    }
    columns {
      name = "dstport"
      type = "int"
    }
    columns {
      name = "protocol"
      type = "bigint"
    }
    columns {
      name = "packets"
      type = "bigint"
    }
    columns {
      name = "bytes"
      type = "bigint"
    }
    columns {
      name = "start"
      type = "bigint"
    }
    columns {
      name = "end"
      type = "bigint"
    }
    columns {
      name = "action"
      type = "string"
    }
    columns {
      name = "log_status"
      type = "string"
    }
  }
}
