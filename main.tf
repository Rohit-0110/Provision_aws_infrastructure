provider "aws" {
    region = "us-east-1"
    access_key = "AKIAS3ET7ZJHWPCIMXXI"
    secret_key = "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"
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "availability_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}

resource "aws_vpc" "myapp-vpc"{
    cidr_block = var.vpc_cidr_block
    tags = {
        "Name" = "${var.env_prefix}-vpc"
    } 
}

resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.availability_zone
    tags = {
      "Name" = "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        "Name" = "${var.env_prefix}-igw"
    }

}

/*resource "aws_route_table" "myapp-aws_route_table" {
    vpc_id = aws_vpc.myapp-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    
    tags = {
        "Name" =  "${var.env_prefix}-rtb"
    }
}*/

/*resource "aws_route_table_association" "b-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-aws_route_table.id
}*/

resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    
    tags = {
        "Name" =  "${var.env_prefix}-rtb"
    }
}

resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []    
    }

    tags = {
        "Name" = "${var.env_prefix}-sg"
    }
}

data "aws_ami" "lst-amazon-linux-image"{
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

output "aws_ami_id" {
    value = data.aws_ami.lst-amazon-linux-image.id
}

/*output "ec2_public_ip" {
    value = aws_instance.myapp-server.my_ip
}*/

resource "aws_key_pair" "ssh-key" {
    key_name = "secret_key"
    public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.lst-amazon-linux-image.id
    instance_type = var.instance_type
    
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.availability_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    user_data = file("script.sh")
    
                
    tags = {
        "Name" = "${var.env_prefix}-server"
    } 
}