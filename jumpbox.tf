resource "aws_security_group" "jumpbox" {
  count = var.enable_jumpbox_instance ? 1 : 0

  name        = local.jumpbox_name
  description = "${local.vpc_name} jumpbox instance security group"
  vpc_id      = aws_vpc.current.id

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
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.jumpbox[0].id]
  iam_instance_profile   = aws_iam_instance_profile.main.id

  tags = merge(local.common_tags, { Name = local.jumpbox_name })
}

