# VPC

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "Demo_vpc"
  }
}

# public subnet

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.aws_subnet_public
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}


# private subnet

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.aws_subnet_private

  tags = {
    Name = "private-subnet"
  }
}

# Internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW"
  }
}

# public route table

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }


  tags = {
    Name = "public_RT"
  }
}

# private route table

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private_RT"
  }
}

# EIP 

resource "aws_eip" "lb" {
  domain = "vpc"

  tags = {
    Name = "eip"
  }
}

# NAT 

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "gw NAT"
  }

}

# public Route table association

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#  private route table association


resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits = 4096  
}

resource "aws_key_pair" "kp" {
  key_name = "test-key"
  public_key = tls_private_key.pk.public_key_openssh
  
}

# Security Group

resource "aws_security_group" "example" {
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.main.id

  # Inbound rules

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "security-group-1"
  }
}

resource "aws_instance" "public_instance" {
  ami             = "ami-0b20f552f63953f0e"
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.public.id
  key_name = "${aws_key_pair.kp.key_name}"
  security_groups = [aws_security_group.example.id]

  tags = {
    Name = "Nginx-NodeJS-Server"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx

              # Install Ansible
              sudo apt install software-properties-common
              sudo add-apt-repository --yes --update ppa:ansible/ansible
              sudo apt install ansible
              apt install ansible-core
      

              EOF
}



resource "aws_instance" "server1_instance" {
  ami           = "ami-0b20f552f63953f0e"
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
   key_name = "${aws_key_pair.kp.key_name}"
  security_groups = [aws_security_group.example.id]

  tags = {
    Name = "server1"
  }
}

