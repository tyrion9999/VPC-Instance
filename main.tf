terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
# Create a VPC
resource "aws_vpc" "prod" {
  cidr_block = "10.10.0.0/16"
  tags ={
      Name= "sampleVPC"
  }
}
# create a public subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.prod.id
  availability_zone = "us-east-1a"
  cidr_block = "10.10.1.0/24"
  tags = {
    Name = "Prod_public_subnet"
  }
}
# create a private subnet
resource "aws_subnet" "private"{
    vpc_id = aws_vpc.prod.id
     availability_zone = "us-east-1a"
    cidr_block = "10.10.2.0/24"
    tags = {
        Name = " Prod_private_subnet"
    }
}
# create a internet Gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.prod.id
  tags = {
    Name = "Prod_IGW"
  }
}
# create a Elastic IP for NAT gateway
resource "aws_eip" "EIP"{
      vpc = true
}
# create a NAT gateway
resource "aws_nat_gateway" "NAT"{
   allocation_id = aws_eip.EIP.id
    subnet_id = aws_subnet.public.id
    tags={
        name = "gw NAT"
    }
    depends_on = [aws_internet_gateway.IGW]
}
# Create a Route table for IGW
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.prod.id
  tags = {
    Name = "prod_RT"
  }
}
# Create route table for NGW
resource "aws_route_table" "RTNGW"{
    vpc_id = aws_vpc.prod.id
    tags={
        Name ="prod_RTNGW"
    }
}
# Route table associating with public subnet
resource "aws_route_table_association" "RTA" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.RT.id
}
# Route table associating with private subnet
resource "aws_route_table_association" "RTANGW" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.RTNGW.id
}
# Route to connect publicsubnet to internet gateway
resource "aws_route" "R" {
  route_table_id         = aws_route_table.RT.id
  gateway_id             = aws_internet_gateway.IGW.id
  destination_cidr_block = "0.0.0.0/0"
}
# Route to connect privatesubnet to NAT gateway
resource "aws_route" "RNAT" {
  route_table_id         = aws_route_table.RTNGW.id
  gateway_id             = aws_nat_gateway.NAT.id
  destination_cidr_block = "0.0.0.0/0"
}
# create security group
resource "aws_security_group" "SG"{
     vpc_id = aws_vpc.prod.id 
    tags = {
    Name = "allow_tls"
  }
}

# Create a security group rule for Inbound rules

resource "aws_security_group_rule" "Inbound" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = aws_security_group.SG.id
  
 }
 # Create a security group rule for Outbound rules
resource "aws_security_group_rule" "Outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  #ipv6_cidr_blocks  = [aws_vpc.example.ipv6_cidr_block]
  security_group_id = aws_security_group.SG.id
  
}

# create an instance
resource "aws_instance" "web"{
    ami                    = "ami-087c17d1fe0178315"
    instance_type          = "t2.micro"
  key_name               = "dev-virginia"
  count  =  10
  subnet_id      = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids = [ aws_security_group.SG.id  ]
  tags={
    Name = "somu"
  }
}
