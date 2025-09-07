provider "aws" {
  region = "eu-north-1"
}

module "vpc" {
  source         = "../../modules/vpc"
  name           = "dev"
  cidr           = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24","10.0.2.0/24"]
  private_subnets= ["10.0.101.0/24","10.0.102.0/24"]
}

module "eks" {
  source          = "../../modules/eks"
  cluster_name    = "dev-eks"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}

module "alb" {
  source          = "../../modules/alb"
  name            = "dev"
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  security_groups = [module.eks.cluster_security_group_id]
}

module "iam" {
  source = "../../modules/iam"
}

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

# Data sources for EKS cluster (ADD THESE TO MAIN.TF)
data "aws_eks_cluster" "dev_cluster" {
  name = "dev-eks"
}

data "aws_eks_cluster_auth" "dev_cluster" {
  name = "dev-eks"
}

# Providers for Kubernetes and Helm (ADD THESE TO MAIN.TF)
provider "kubernetes" {
  host                   = data.aws_eks_cluster.dev_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.dev_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.dev_cluster.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.dev_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.dev_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.dev_cluster.token
  }
}