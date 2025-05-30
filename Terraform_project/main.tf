resource "aws_directory_service_directory" "my-ad" {
  name     = "my.corp.com"
  password = "SuperSecretPassw0rd"
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = aws_vpc.my-vpc.id
    subnet_ids = [aws_subnet.public-subnet-east-1a.id, aws_subnet.public-subnet-east-1b.id]
  }

  tags = {
    Project = "My-SQL-Cluster"
  }
}

resource "aws_vpc_dhcp_options" "ad_dhcp_options" {
  domain_name         = "corp.com"
  domain_name_servers = aws_directory_service_directory.my-ad.dns_ip_addresses
  tags = {
    Name = "ad-dhcp-options"
  }
}

resource "aws_vpc_dhcp_options_association" "ad_dhcp_association" {
  vpc_id          = aws_vpc.my-vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.ad_dhcp_options.id
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2-directory-join-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ad" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-directory-profile"
  role = aws_iam_role.ec2_role.name
}


resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ec2_ssm_instance_profile"
  role = aws_iam_role.ec2_role.name
}


resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "My-VPC"
  }
}

resource "aws_subnet" "public-subnet-east-1a" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-east-1a"
  }
}

resource "aws_subnet" "public-subnet-east-1b" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-east-1b"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id
  tags = {
    Name = "My-VPC-IGW"
  }
}

resource "aws_route" "public-route" {
  route_table_id         = aws_route_table.public-route-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my-igw.id
}

resource "aws_route_table_association" "public-subnet-east-1a-association" {
  subnet_id      = aws_subnet.public-subnet-east-1a.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-subnet-east-1b-association" {
  subnet_id      = aws_subnet.public-subnet-east-1b.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_security_group" "web-sg" {
  vpc_id = aws_vpc.my-vpc.id
  name   = "web-sg"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 88
    to_port     = 464
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

data "aws_subnet" "public-subnet-east-1a" {
  id = aws_subnet.public-subnet-east-1a.id
}

data "aws_subnet" "public-subnet-east-1b" {
  id = aws_subnet.public-subnet-east-1b.id
}

resource "aws_key_pair" "tf_key" {
  key_name   = "tfkey"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "tf-key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tfkey.pem"
}

resource "aws_instance" "servers" {
  for_each      = var.instances
  ami           = each.value.ami
  instance_type = each.value.instance_type
  subnet_id = (
    each.key == "instance1" ? data.aws_subnet.public-subnet-east-1a.id :
    each.key == "instance2" ? data.aws_subnet.public-subnet-east-1b.id :
    null
  )
  iam_instance_profile   = aws_iam_instance_profile.ssm_instance_profile.name
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  key_name               = "tfkey"
  tags = {
    Name = "${each.key}"
  }
}

resource "aws_s3_bucket" "script_bucket" {
  bucket        = "my-script-bucket-unique-name"
  force_destroy = true
}

locals {
  script_path = "scripts/enablealwayson.ps1"
  script_md5  = filemd5(local.script_path)
}

resource "aws_s3_object" "ps_script" {
  bucket = aws_s3_bucket.script_bucket.id
  key    = "enablealwayson.ps1"
  source = local.script_path
  etag   = local.script_md5

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [etag]
  }
}

locals {
  run_script_command = templatefile("${path.module}/enablealwayson.tpl.ps1", {
    bucket = aws_s3_bucket.script_bucket.bucket
    key    = aws_s3_object.ps_script.key
  })
}

resource "aws_ssm_association" "run_script" {
  for_each = aws_instance.servers
  name     = "AWS-RunPowerShellScript"
  targets {
    key    = "InstanceIds"
    values = [each.value.id]
  }

  parameters = {
    commands = local.run_script_command
  }
}