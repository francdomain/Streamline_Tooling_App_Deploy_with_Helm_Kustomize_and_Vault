output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnets
  description = "List of public subnet IDs from the VPC module"
}

output "eks_oidc_url" {
  value = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}
