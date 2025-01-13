module "vault_iam_role" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version     = "5.47.1"
  role_name   = "vaultKMS"
  create_role = true
  role_policy_arns = {
    AWSKeyManagementServicePowerUser = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
  }

  oidc_providers = {
    main = {
      provider_arn               = "arn:aws:iam::992382613070:oidc-provider/oidc.eks.us-west-1.amazonaws.com/id/434374DCC1195C390F2D87B27DAE3AC9" # module.eks.dev_eks_oidc_provider_arn #data.aws_eks_cluster.dev-eks.identity[0].oidc[0].issuer
      namespace_service_accounts = ["vault:vault-kms"]
    }
  }

  tags = var.tags

}

module "vault_kms_key" {
  source                  = "terraform-aws-modules/kms/aws"
  version                 = "3.1.1"
  description             = "Vault Cluster KMS Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false

  # Policy
  enable_default_policy = true
  key_owners            = [module.vault_iam_role.iam_role_arn]
  key_administrators    = [module.vault_iam_role.iam_role_arn]

  # Aliases
  aliases                 = ["dev-vault-kms"]
  aliases_use_name_prefix = true

  # Grants
  grants = {}

  tags = var.tags
}
