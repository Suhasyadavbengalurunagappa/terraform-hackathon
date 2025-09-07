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
  region = "eu-north-1"  # same region as your ECR images
}

# Data sources for EKS cluster info
data "aws_eks_cluster" "dev_cluster" {
  name = "dev-eks"
}

data "aws_eks_cluster_auth" "dev_cluster" {
  name = "dev-eks"
}

# Kubernetes and Helm providers
provider "kubernetes" {
  host                   = data.aws_eks_cluster.dev_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.dev_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.dev_cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.dev_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.dev_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.dev_cluster.token
  }
}
