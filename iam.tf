resource "aws_iam_instance_profile" "main" {
  count = var.iam_instance_profile_name == null ? 1 : 0

  name = var.name
  role = aws_iam_role.main[0].name

  tags = var.tags
}

data "aws_iam_policy_document" "main" {
  count = var.iam_instance_profile_name == null ? 1 : 0

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
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Name"
      values   = [local.instance_name]
    }
  }

  dynamic "statement" {
    for_each = length(var.eip_allocation_ids) != 0 ? ["x"] : []

    content {
      sid    = "ManageEIPAllocation"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = [
        "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:elastic-ip/${var.eip_allocation_ids[0]}",
      ]
    }
  }

  dynamic "statement" {
    for_each = length(var.eip_allocation_ids) != 0 ? ["x"] : []

    content {
      sid    = "ManageEIPNetworkInterface"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = [
        "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:network-interface/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "ec2:ResourceTag/Name"
        values   = [local.instance_name]
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
  count = var.iam_instance_profile_name == null ? 1 : 0

  name   = var.name
  policy = data.aws_iam_policy_document.main[0].json
  tags   = var.tags
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  count = var.iam_instance_profile_name == null ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "main" {
  count = var.iam_instance_profile_name == null ? 1 : 0

  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "main" {
  count = var.iam_instance_profile_name == null ? 1 : 0

  role       = aws_iam_role.main[0].name
  policy_arn = aws_iam_policy.main[0].arn
}
