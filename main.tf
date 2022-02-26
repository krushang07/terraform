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
  profile = "default"
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket = "remote-statefile"
    key    = "mystatefile"
    region = "us-east-1"
  }
}

module "vpc" {
  source = "./modules/vpc"

  region               = "ap-south-1"
  vpc_cidr             = "10.10.0.0/16"
  name                 = "vpc"
  env                  = "dev"
  public_subnets_cidr  = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnets_cidr = ["10.10.3.0/24", "10.10.4.0/24"]
  availability_zones   = ["ap-south-1a", "ap-south-1b"]
}


module "webservers" {
  source = "./modules/asg-alb"
  cluster_name = "webservers-dev"
  instance_type = "t2.micro"
  min_size      = 1
  max_size      = 2
  desired_capacity  = 1
}    
