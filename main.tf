# VPC creation
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "var.vpc_name"
  }
}
# Internet Gateway and attach to vpc
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.var.vpc_name.id

  tags = {
    Name = "var.IGW"
  }
}
# Create Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.var.vpc_name.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = var.Public-Subnet
  }
}
# Create Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.var.vpc_name.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = var.Private-Subnet
  }
}
# Create Elastic IP
resource "aws_eip" "nat_eip" {
  domain   = "vpc"
}

# Create NAT Gateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = var.natgw
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.IGW]
}

# Route Table and route
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.var.vpc_name.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "public_route"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.var.vpc_name.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "private_route"
  }
}

# Subnet association with route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route.id
}


# Create Security Group
resource "aws_security_group" "WebSG" {
  name        = var.WebSG
  vpc_id      = aws_vpc.var.vpc_name.id

  tags = {
    Name = var.WebSG
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.WebSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH" {
  security_group_id = aws_security_group.WebSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.WebSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# Generate an RSA private key using the TLS provider
resource "tls_private_key" "my_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an EC2 Key Pair in AWS using the public key
resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-ec2-key"  # Name for the key pair in AWS
  public_key = tls_private_key.my_private_key.public_key_openssh  # Use the OpenSSH formatted public key
}

# Save the private key to a file in /root/terraform-templates
resource "local_file" "private_key" {
  content  = tls_private_key.my_private_key.private_key_pem
  filename = "/root/terraform-templates/my-ec2-key.pem"  # Save the private key in this path
}

#Create EC2 Instance
resource "aws_instance" "PublicWebServer" {
  ami           = "ami-0df8c184d5f6ae949"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  key_name = aws_key_pair.my_key_pair.key_name
  tags = {
    Name = var.PublicWebServer
  }
  }
#Create EC2 Instance
  resource "aws_instance" "PrivateServer" {
  ami           = "ami-0df8c184d5f6ae949"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  associate_public_ip_address = false
  key_name = aws_key_pair.my_key_pair.key_name
  tags = {
    Name = var.PrivateServer
  }
  }
