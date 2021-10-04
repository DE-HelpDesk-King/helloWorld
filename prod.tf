variable "whitelist" {
  type = list(string)
}
variable "web_image_id" {
  type = string
}
variable "web_instance_type" {
  type = string
}
variable "web_desired_capacity" {
  type = number
}
variable "web_max_size" {
  type = number
}
variable "web_min_size" {
  type = number
}

provider "aws" {
   profile =  "default"
   region  = "us-west-2"
}

resource "aws_s3_bucket" "prod_tf_hello_word"{
  bucket   = "tf-helloworld-20212709"
  acl      = "private"
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1"{
  availability_zone = "us-west-2a"
  tags = {
    "Terraform" : "true"
  }
}

resource "aws_default_subnet" "default_az2"{
  availability_zone = "us-west-2b"
  tags = {
    "Terraform" : "true"
  }
}


resource "aws_security_group" "prod_web_hello_world" {
  name        = "prod_web_hello_world"
  description = "Allow standard http and https ports inbound and everything outbound"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.whitelist
  }  

  tags = {
  "Terraform" : "true"
  }
}

module "web_app" {
  source = "./modules/web_app"

  web_image_id         = var.web_image_id
  web_instance_type    = var.web_instance_type
  web_desired_capacity = var.web_desired_capacity
  web_max_size         = var.web_max_size
  web_min_size         = var.web_min_size
  subnets              = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  security_groups      = [aws_security_group.prod_web_hello_world.id]
  web_app              = "prod"
}

terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name = "nginx:latest"
  keep_locally = false
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.latest
  name = "tutorial"
  ports {
    internal = 80
    external = 80
  }
  upload {
    source = "src/hello_world.html"
    file = "/usr/share/nginx/html/index.html"
  }
}
