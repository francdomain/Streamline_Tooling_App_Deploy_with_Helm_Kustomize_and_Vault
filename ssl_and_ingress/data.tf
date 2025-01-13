# get all available AZs in our region
data "aws_availability_zones" "available_azs" {
  state = "available"
}
data "aws_caller_identity" "current" {} # used for accesing Account ID and ARN

# get EKS cluster info to configure Kubernetes and Helm providers
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}
data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

data "aws_partition" "current" {}

# Get DNS name of the ELB created by the Ingress Controller.

data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  }

  depends_on = [
    helm_release.ingress_nginx_controller
  ]
}

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

data "aws_lb_hosted_zone_id" "main" {
  region             = var.aws_region
  load_balancer_type = "network"
}

# Fetch the OIDC provider based on the URL from the EKS cluster
data "aws_iam_openid_connect_provider" "existing_oidc_provider" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

data "tls_certificate" "eks" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

# Update Kubeconfig After Cluster Creation
resource "null_resource" "update_kubeconfig" {

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${data.aws_eks_cluster.cluster.name} --region ${var.aws_region} --kubeconfig ${path.module}/kubeconfig"

    environment = {
      cluster_endpoint = data.aws_eks_cluster.cluster.endpoint
    }
  }
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${data.aws_eks_cluster.cluster.name} --region ${var.aws_region}"

    environment = {
      cluster_endpoint = data.aws_eks_cluster.cluster.endpoint
    }
  }

  # triggers = {
  #   # cluster_endpoint = module.eks_cluster.cluster_endpoint
  #   cluster_endpoint = data.aws_eks_cluster.cluster.cluster_endpoint
  #   cluster_name     = var.cluster_name
  # }
}
