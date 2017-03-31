variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "ap-northeast-1"
}
variable "key_pair_name" {}
variable "pvivate_key_path" {}


provider "aws" {
    access_key = "${var.AWS_ACCESS_KEY_ID}"
    secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
    region = "ap-northeast-1"
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "10.0.1.0/24"
}

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.main.id}"
}

resource "aws_route" "route_to_igw" {
    route_table_id = "${aws_vpc.main.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
}

resource "aws_route_table_association" "a" {
    subnet_id = "${aws_subnet.main.id}"
    route_table_id = "${aws_vpc.main.main_route_table_id}"
}

resource "aws_security_group" "allow_ssh_httpd" {
    name = "allow_ssh_httpd"
    description = "Allow ssh and HTTP inbound traffic"
    vpc_id = "${aws_vpc.main.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "web" {
    depends_on = ["aws_internet_gateway.igw"]
    ami = "ami-56d4ad31"
    key_name = "${var.KEY_PAIR_NAME}"
    subnet_id = "${aws_subnet.main.id}"
    vpc_security_group_ids = ["${aws_security_group.allow_ssh_httpd.id}"]
    instance_type = "t2.micro"
    tags {
        Name = "Terraform"
    }
}

resource "aws_eip" "web" {
    depends_on = ["aws_internet_gateway.igw"]
    instance = "${aws_instance.web.id}"
    vpc = true

}
