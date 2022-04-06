#
# AWS Config Service
#

resource "aws_config_configuration_recorder" "ConfigurationRecorder" {
  role_arn = aws_iam_role.ConfigIamRole.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "DeliveryChannel" {
  s3_bucket_name = aws_s3_bucket.S3BucketForConfig.id
  depends_on = [ aws_config_configuration_recorder.ConfigurationRecorder ]
}

resource "aws_config_configuration_recorder_status" "ConfigurationRecorderStatus" {
  name = aws_config_configuration_recorder.ConfigurationRecorder.name
  is_enabled = true
  depends_on = [ aws_config_delivery_channel.DeliveryChannel ]
}

resource "aws_s3_bucket" "S3BucketForConfig" {
  bucket = "s3-config-bucket-kjhbfv"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryptS3" {
  bucket = aws_s3_bucket.S3BucketForConfig.bucket

  rule {
    apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_role" "ConfigIamRole" {
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["config.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ConfigIamRoleManagedPolicyRoleAttachment0" {
  role = aws_iam_role.ConfigIamRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_iam_role_policy" "ConfigIamRoleInlinePolicyRoleAttachment0" {
  name = "allow-access-to-config-s3-bucket"
  role = aws_iam_role.ConfigIamRole.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::s3-config-bucket-kjhbfv/*"
            ],
            "Condition": {
                "StringLike": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketAcl"
            ],
            "Resource": "arn:aws:s3:::s3-config-bucket-kjhbfv"
        }
    ]
}
POLICY
}

resource "aws_config_config_rule" "ConfigRule" {
  name = "s3-bucket-server-side-encryption-enabled"
  description = "A Config rule that checks that your Amazon S3 bucket either has Amazon S3 default encryption enabled."

  source {
    owner = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
  depends_on = [aws_config_configuration_recorder.main]
}
