module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.1.5"           # module version

  name               = var.cluster_name
  kubernetes_version = "1.32"
  vpc_id             = var.vpc_id
  subnet_ids         = var.private_subnets

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "default"
        },
        {
          namespace = "kube-system"
        }
      ]
    }
  }

  # No node_groups needed if only Fargate
}
