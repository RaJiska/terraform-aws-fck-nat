data "aws_iam_policy_document" "jumpbox" {
  count = var.enable_jumpbox_instance ? 1 : 0

  statement {
    sid    = "SessionManager"
    effect = "Allow"
    actions = [
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenDataChannel",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:OpenControlChannel",
      "ssm:UpdateInstanceInformation",
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "jumpbox" {
  count = var.enable_jumpbox_instance ? 1 : 0

  name   = local.jumpbox_iam_name
  policy = data.aws_iam_policy_document.jumpbox[0].json
  tags   = merge(local.common_tags, { Name = local.jumpbox_iam_name })
}

resource "aws_iam_role" "jumpbox" {
  count = var.enable_jumpbox_instance ? 1 : 0

  name                 = local.jumpbox_iam_name
  assume_role_policy   = data.aws_iam_policy_document.instance_assume_role_policy.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = merge(local.common_tags, { Name = local.jumpbox_iam_name })
}

resource "aws_iam_role_policy_attachment" "jumpbox" {
  count = var.enable_jumpbox_instance ? 1 : 0

  role       = aws_iam_role.jumpbox[0].name
  policy_arn = aws_iam_policy.jumpbox[0].arn
}

resource "aws_iam_instance_profile" "jumpbox" {
  count = var.enable_jumpbox_instance ? 1 : 0

  name = local.jumpbox_iam_name
  role = aws_iam_role.jumpbox[0].name

  tags = merge(local.common_tags, { Name = local.jumpbox_iam_name })
}

resource "aws_security_group" "jumpbox" {
  count = var.enable_jumpbox_instance ? 1 : 0

  name        = local.jumpbox_name
  description = "${local.vpc_name} jumpbox instance security group"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = local.jumpbox_name })
}

resource "aws_instance" "jumpbox" {
  count = var.enable_jumpbox_instance ? 1 : 0

  ami                    = local.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[local.azs[2]].id
  vpc_security_group_ids = [aws_security_group.jumpbox[0].id]
  iam_instance_profile   = aws_iam_instance_profile.jumpbox[0].id

  dynamic "instance_market_options" {
    for_each = var.jumpbox_use_spot_instance ? [true] : []

    content {
      market_type = "spot"

      spot_options {
        instance_interruption_behavior = "terminate"
        spot_instance_type             = "one-time"
      }
    }
  }

  root_block_device {
    encrypted  = true
    kms_key_id = var.kms_key_id
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(local.common_tags, { Name = local.jumpbox_name })
}


