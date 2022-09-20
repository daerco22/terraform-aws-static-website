resource "aws_vpc" "projectone_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "ProjectOne"
  }
}

resource "aws_subnet" "projectone_public_subnet" {
  vpc_id                  = aws_vpc.projectone_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-1a"

  tags = {
    Name = "ProjectOne-Public"
  }
}

resource "aws_internet_gateway" "projectone_internet_gateway" {
  vpc_id = aws_vpc.projectone_vpc.id

  tags = {
    Name = "ProjectOne-igw"
  }
}

resource "aws_route_table" "projectone_public_rt" {
  vpc_id = aws_vpc.projectone_vpc.id
}

resource "aws_route" "projectone_default_route" {
  route_table_id         = aws_route_table.projectone_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.projectone_internet_gateway.id
}

resource "aws_route_table_association" "projectone_public_assoc" {
  subnet_id      = aws_subnet.projectone_public_subnet.id
  route_table_id = aws_route_table.projectone_public_rt.id
}

resource "aws_security_group" "projectone_sg" {
  name        = "ProjectOne_SG"
  description = "Project One Security Group"
  vpc_id      = aws_vpc.projectone_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.local_ip}/32","${var.other_local_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "projectone_auth" {
  key_name   = "mtc-key"
  public_key = file("~/.ssh/mtckey.pub")
}

resource "aws_instance" "projectone_node" {
  ami                    = data.aws_ami.server_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.projectone_auth.id
  vpc_security_group_ids = [aws_security_group.projectone_sg.id]
  subnet_id              = aws_subnet.projectone_public_subnet.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "ProjectOne-Node"
  }

  provisioner "local-exec" {
    command = templatefile("windows-ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu"
      identityfile = "~/.ssh/mtckey"
    })
    interpreter = ["Powershell", "-Command"]
  }
}