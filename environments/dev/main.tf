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
