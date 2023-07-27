terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "imersao_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1" # Use the latest available version

  name            = "imersao_vpc"
  cidr            = "10.0.0.0/16"  # Corrected CIDR block without the trailing dot
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks
  azs             = var.azs

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/imersao-eks" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/imersao-eks" = "shared"
    "kubernetes.io/role/elb"            = 1
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/imersao-eks"  = "shared"
    "kubernetes.io/cluster/internal-elb" = 1
  }
}

module "imersao-eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "imersao-eks"
  cluster_version = "1.27"

  subnet_ids                     = module.imersao_vpc.private_subnets
  vpc_id                         = module.imersao_vpc.vpc_id
  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    live = {
      min_size     = 1
      max_size     = 3
      desired_size = 3

      instance_types = ["t3.micro"]
    }
  }
}

variable "vpc_cidr" {}
variable "private_subnet_cidr_blocks" {}
variable "public_subnet_cidr_blocks" {}
variable "azs" {}
variable "region" {}
