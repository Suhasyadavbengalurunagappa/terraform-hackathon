# AWS Load Balancer Controller Resources

# Data sources for EKS cluster (needed for this file)
data "aws_eks_cluster" "dev_cluster" {
  name = "dev-eks"
}

data "aws_eks_cluster_auth" "dev_cluster" {
  name = "dev-eks"
}

# Data source for OIDC provider
data "aws_iam_openid_connect_provider" "eks_oidc" {
  url = data.aws_eks_cluster.dev_cluster.identity[0].oidc[0].issuer
}

# IAM Role for AWS Load Balancer Controller
resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "AmazonEKSLoadBalancerControllerRole-dev"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks_oidc.arn
        }
        Condition = {
          StringEquals = {
            "${replace(data.aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${replace(data.aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "AmazonEKSLoadBalancerControllerRole-dev"
    Environment = "dev"
  }
}

# Attach AWS managed policy for Load Balancer Controller
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_policy" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

# Kubernetes Service Account for AWS Load Balancer Controller
resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }
  }
}

# Install AWS Load Balancer Controller via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.4.4"

  values = [
    yamlencode({
      clusterName = "dev-eks"
      serviceAccount = {
        create = false
        name   = kubernetes_service_account.aws_load_balancer_controller.metadata[0].name
      }
      region = "eu-north-1"
      vpcId  = module.vpc.vpc_id
    })
  ]

  depends_on = [
    kubernetes_service_account.aws_load_balancer_controller
  ]
}

# Output the ALB DNS name for reference (only if you want to keep your existing ALB)
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}