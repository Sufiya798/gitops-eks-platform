terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state - create this S3 bucket + DynamoDB table once, manually or
  # via the multi-env-terraform project, before running `terraform init` here.
  backend "s3" {
    bucket         = "sufiya-gitops-eks-tfstate"   # <-- change to your own bucket name
    key            = "gitops-eks-platform/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source           = "../modules/vpc"
  name             = var.cluster_name
  cidr_block       = "10.0.0.0/16"
  azs              = var.azs
  public_subnets   = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets  = ["10.0.10.0/24", "10.0.11.0/24"]
  tags             = var.tags
}

module "iam" {
  source       = "../modules/iam"
  cluster_name = var.cluster_name
  tags         = var.tags
}

module "eks" {
  source            = "../modules/eks"
  cluster_name      = var.cluster_name
  cluster_version   = var.cluster_version
  subnet_ids        = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  node_subnet_ids   = module.vpc.private_subnet_ids
  cluster_role_arn  = module.iam.cluster_role_arn
  node_role_arn     = module.iam.node_role_arn
  instance_types    = ["t3.medium"]
  desired_size      = 2
  min_size          = 1
  max_size          = 3
  tags              = var.tags
}
