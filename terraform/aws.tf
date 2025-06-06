provider "aws" {
  # asia pacific (hong kong)
  region     = "ap-east-1"
  access_key = data.sops_file.terraform.data["aws.access-key"]
  secret_key = data.sops_file.terraform.data["aws.secret-key"]
}

resource "aws_instance" "main" {
  count = 0 # disabled

  instance_type = "t3.micro"
  ami           = data.aws_ami.nixos_x86_64.id

  subnet_id = aws_subnet.main_1.id

  key_name = aws_key_pair.pgp.key_name

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp2"
    volume_size           = 20 # GiB
  }

  # user_data_replace_on_change = true
  user_data = templatefile("${path.module}/aws/initialize.sh",
    {
      config_name          = "aws",
      host_ed25519_key     = data.sops_file.terraform.data["aws.ed25519-key"],
      host_ed25519_key_pub = data.sops_file.terraform.data["aws.ed25519-key-pub"],
  })
}

resource "aws_eip" "main" {
  count = 0 # disabled

  instance = aws_instance.main[count.index].id
  domain   = "vpc"
}

locals {
  nixos_state_version = jsondecode(file("${path.module}/../lib/state-version.json"))
}

data "aws_ami" "nixos_x86_64" {
  owners      = ["427812963091"]
  most_recent = true

  filter {
    name   = "name"
    values = ["nixos/${local.nixos_state_version}*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"] # or "x86_64"
  }
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
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }
}

resource "aws_key_pair" "pgp" {
  key_name   = "pgp"
  public_key = file("${path.module}/../nixos/profiles/users/root/_ssh/pgp.pub")
}
