resource "aws_iam_instance_profile" "main" {
  name = local.iam_name
  role = aws_iam_role.main.name

  tags = merge(local.common_tags, { Name = local.iam_name })
}

data "aws_iam_policy_document" "main" {
  statement {
    sid    = "ManageNetworkInterface"
    effect = "Allow"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/Name"
      values   = ["${local.name}-${local.region}*"]
    }
  }

  dynamic "statement" {
    for_each = var.eip_allocation_ids

    content {
      sid    = "ManageEIPAllocation${replace(statement.key, "-", "")}"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = [
        "arn:${data.aws_partition.current.partition}:ec2:${local.region}:${local.account_id}:elastic-ip/${statement.value}",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.eip_allocation_ids

    content {
      sid    = "ManageEIPNetworkInterface${replace(statement.key, "-", "")}"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = [
        "arn:${data.aws_partition.current.partition}:ec2:${local.region}:${local.account_id}:network-interface/*"
      ]
      condition {
        test     = "StringLike"
        variable = "ec2:ResourceTag/Name"
        values   = ["${local.name}-${statement.key}"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.use_cloudwatch_agent ? ["x"] : []

    content {
      sid    = "CWAgentSSMParameter"
      effect = "Allow"
      actions = [
        "ssm:GetParameter"
      ]
      resources = [
        local.cwagent_param_arn
      ]
    }
  }

  dynamic "statement" {
    for_each = var.use_cloudwatch_agent ? ["x"] : []

    content {
      sid    = "CWAgentMetrics"
      effect = "Allow"
      actions = [
        "cloudwatch:PutMetricData"
      ]
      resources = [
        "*"
      ]
      condition {
        test     = "StringEquals"
        variable = "cloudwatch:namespace"
        values   = [var.cloudwatch_agent_configuration.namespace]
      }
    }
  }

  dynamic "statement" {
    for_each = var.attach_ssm_policy ? ["x"] : []

    content {
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
}

resource "aws_iam_policy" "main" {
  name   = local.iam_name
  policy = data.aws_iam_policy_document.main.json
  tags   = merge(local.common_tags, { Name = local.iam_name })
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "main" {
  name                 = local.iam_name
  assume_role_policy   = data.aws_iam_policy_document.instance_assume_role_policy.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = merge(local.common_tags, { Name = local.iam_name })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}
