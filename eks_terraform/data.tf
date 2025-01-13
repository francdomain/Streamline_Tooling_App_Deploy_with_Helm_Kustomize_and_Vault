# get all available AZs in our region
data "aws_availability_zones" "available_azs" {
  state = "available"
}
data "aws_caller_identity" "current" {} # used for accesing Account ID and ARN

# Wait for eks cluster to be ready
resource "time_sleep" "wait_for_cluster" {
  create_duration = "60s"
}

# get EKS cluster info to configure Kubernetes and Helm providers
data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_name
  depends_on = [
    time_sleep.wait_for_cluster
  ]
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
}

data "aws_partition" "current" {}

data "aws_eks_addon_version" "this" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = module.eks_cluster.cluster_version
  most_recent        = true
}

# Fetch the OIDC provider based on the URL from the EKS cluster
data "aws_iam_openid_connect_provider" "existing_oidc_provider" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer

  depends_on = [
    module.eks_cluster
  ]
}
