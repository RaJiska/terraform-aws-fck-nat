resource "aws_iam_instance_profile" "main" {
  name = var.name
  role = aws_iam_role.main.name
}

data "aws_iam_policy_document" "main" {
  statement {
    sid = "ManageNetworkInterface"
    effect = "Allow"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
    ]
    resources = [
      "*",
    ]
    condition {
      test = "StringEquals"
      variable = "ec2:ResourceTag/Name"
      values = [var.name]
    }
  }

  dynamic "statement" {
    for_each = var.eip_allocation_id != null ? ["x"] : []

    content {
      sid = "ManageEIPAllocation"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:elastic-ip/${var.eip_allocation_id}",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.eip_allocation_id != null ? ["x"] : []

    content {
      sid = "ManageEIPNetworkInterface"
      effect = "Allow"
      actions = [
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
      ]
      resources = [
        "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
      ]
      condition {
        test = "StringEquals"
        variable = "ec2:ResourceTag/Name"
        values = [var.name]
      }
    }
  }
}

resource "aws_iam_role" "main" {
  name = var.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "Main"
    policy = data.aws_iam_policy_document.main.json
  }
}
