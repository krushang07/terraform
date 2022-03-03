provider "aws" {
  region  = "ap-south-1"
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
  source           = "./modules/asg-alb"
  cluster_name     = "webservers-dev"
  instance_type    = "t2.micro"
  min_size         = 1
  max_size         = 2
  desired_capacity = 1
}

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "demodb"

  engine            = "mysql"
  engine_version    = "5.7.25"
  instance_class    = "db.m5.large"
  allocated_storage = 5

  db_name  = "demodb"
  username = "user"
  port     = "3306"

  iam_database_authentication_enabled = true

  vpc_security_group_ids = ["sg-0387fc29f0e8d0898"]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring - see example for details on how to create the role
  # by yourself, in case you don't want to create it automatically
  monitoring_interval    = "30"
  monitoring_role_name   = "MyRDSMonitoringRole"
  create_monitoring_role = true

  tags = {
    Owner       = "user"
    Environment = "dev"
  }

  # DB subnet group
  create_db_subnet_group = true
  subnet_ids             = ["subnet-0942d2e4919d7c959", "subnet-0927870bd0d2e8658"]

  # DB parameter group
  family = "mysql5.7"

  # DB option group
  major_engine_version = "5.7"

  # Database Deletion Protection
  deletion_protection = false

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  options = [
    {
      option_name = "MARIADB_AUDIT_PLUGIN"

      option_settings = [
        {
          name  = "SERVER_AUDIT_EVENTS"
          value = "CONNECT"
        },
        {
          name  = "SERVER_AUDIT_FILE_ROTATIONS"
          value = "37"
        },
      ]
    },
  ]
}

