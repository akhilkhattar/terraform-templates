# VPC creation
resource "aws_vpc" "whizlabs_VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "whizlabs_VPC"
  }
}
# Internet Gateway and attach to vpc
resource "aws_internet_gateway" "whizlabs_IGW" {
  vpc_id = aws_vpc.whizlabs_VPC.id

  tags = {
    Name = "whizlabs_IGW"
  }
}
# Create Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.whizlabs_VPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public_subnet"
  }
}
# Create Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.whizlabs_VPC.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "private_subnet"
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
    Name = "natgw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.example]
}

# Route Table and route
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.whizlabs_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.whizlabs_IGW.id
  }

  tags = {
    Name = "public_route"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.whizlabs_VPC.id

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

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route.id
}


# Create Security Group
resource "aws_security_group" "WebSG" {
  name        = "WebSG"
  vpc_id      = aws_vpc.whizlabs_VPC.id

  tags = {
    Name = "WebSG"
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


#Create EC2 Instance
resource "aws_instance" "PublicWebServer" {
  ami           = "ami-"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  tags = {
    Name = "PublicWebServer"
  }
  }
#Create EC2 Instance
  resource "aws_instance" "PrivateServer" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  associate_public_ip_address = false
  tags = {
    Name = "PrivateServer"
  }
  }
