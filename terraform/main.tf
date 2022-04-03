resource "aws_instance" "main" {
  instance_type = "t3.micro"
  ami           = module.nixos_image.ami

  subnet_id              = aws_subnet.main_1.id
  vpc_security_group_ids = [aws_security_group.main.id]

  key_name = aws_key_pair.pgp.key_name

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = 20 # GiB
  }
}

module "deploy_nixos" {
  source = "github.com/tweag/terraform-nixos//deploy_nixos"

  flake         = true
  config_pwd    = "${path.module}/.."
  nixos_config  = "aws" # flake
  target_system = "x86_64-linux"

  target_host = aws_instance.main.public_ip
  ssh_agent   = true
}

resource "aws_eip" "main" {
  instance = aws_instance.main.id
  vpc      = true
}

resource "aws_vpc" "main" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true # /56 ipv6 cidr
}

resource "aws_subnet" "main_1" {
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)      # /24 ipv4 cidr
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 0) # /64 ipv6 cidr
  assign_ipv6_address_on_creation = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }
}

resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    description      = "icmpv4"
    from_port        = -1 # all icmp type number
    to_port          = -1 # all icmp code
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }

  ingress {
    description      = "icmpv6"
    from_port        = -1 # all icmp type number
    to_port          = -1 # all icmp code
    protocol         = "icmpv6"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "http"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "zerotier"
    from_port        = 9993
    to_port          = 9993
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "tailscale"
    from_port        = 41641
    to_port          = 41641
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # allow all traffic for egress
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_key_pair" "pgp" {
  key_name   = "pgp"
  public_key = file("${path.module}/../users/yinfeng/ssh/authorized-keys/pgp.pub")
}
