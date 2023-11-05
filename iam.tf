resource "aws_iam_instance_profile" "main" {
  name = var.name
  role = aws_iam_role.main.name
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
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "ManageNetworkInterface"
          Effect = "Allow"
          Action = [
            "ec2:AttachNetworkInterface",
            "ec2:ModifyNetworkInterfaceAttribute"
          ]
          Resource = ["*"],
          Condition = {
            StringEquals = {
              "ec2:ResourceTag/Name" = var.name
            }
          }
        }
      ]
    })
  }
}
