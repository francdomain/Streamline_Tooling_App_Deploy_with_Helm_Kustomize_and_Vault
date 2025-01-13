# Create namespace for cert-manager
resource "kubernetes_namespace" "cert_manager_ns" {
  metadata {
    name = "cert-manager"
    labels = {
      name = "cert-manager"
    }
  }
}

# Create an IAM Policy for Route 53 Access
resource "aws_iam_policy" "cert_manager_route53" {
  name        = "CertManagerRoute53Access"
  description = "Allows cert-manager to create and manage Route 53 records for DNS01 challenges"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Action" : "route53:ChangeResourceRecordSets",
        "Resource" : "arn:aws:route53:::hostedzone/*"
      },
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Action" : [
          "route53:GetChange",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ListHostedZonesByName"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# Create an IAM Role for the Service Account
resource "aws_iam_role" "cert_manager_role" {
  name = "cert-manager-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" : "sts.amazonaws.com",
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:cert-manager:cert-manager"
          }
        }
      }
    ]
  })
}

# Attach the IAM Policy for Route 53 Access to IAM Role for the Service Account
resource "aws_iam_role_policy_attachment" "cert_manager_attach" {
  role       = aws_iam_role.cert_manager_role.name
  policy_arn = aws_iam_policy.cert_manager_route53.arn
}


# Create cert-manager service account
resource "kubernetes_service_account" "cert_manager" {
  metadata {
    name      = "cert-manager"
    namespace = kubernetes_namespace.cert_manager_ns.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cert_manager_role.arn
    }
  }
  automount_service_account_token = true

  depends_on = [
    aws_iam_role.cert_manager_role,
    kubernetes_namespace.cert_manager_ns
  ]
}


## Create RBAC for cert-manager

# Add custom ClusterRole and ClusterRoleBinding resources for cert-manager
resource "kubernetes_cluster_role" "cert_manager" {
  metadata {
    name = "cert-manager"
  }

  # Rule for managing service accounts
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts", "serviceaccounts/token"]
    verbs      = ["create", "get"]
  }

  # Rule for managing CertificateRequests
  rule {
    api_groups = ["cert-manager.io"]
    resources  = ["certificaterequests"]
    verbs      = ["get", "list", "watch", "create", "update", "patch"]
  }

  # Rule for managing leases in coordination.k8s.io
  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "list", "watch", "create", "update", "delete"]
  }

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_cluster_role_binding" "cert_manager_acme_binding" {
  metadata {
    name = "cert-manager-acme-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cert_manager.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cert-manager"
    namespace = "cert-manager"
  }

  depends_on = [helm_release.cert_manager]
}

resource "null_resource" "apply_cert_manager_crds" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.3/cert-manager.crds.yaml"
  }
}

# Install cert-manager
resource "helm_release" "cert_manager" {
  depends_on = [
    kubernetes_service_account.cert_manager,
    null_resource.apply_cert_manager_crds
  ]

  repository = "jetstack"
  name       = "cert-manager"
  chart      = "cert-manager"
  version    = "v1.15.3"
  namespace  = kubernetes_namespace.cert_manager_ns.metadata[0].name
  timeout    = 600

  # Ensure Terraform knows not to create the service account
  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "webhook.enabled"
    value = true
  }

  set {
    name  = "cainjector.enabled"
    value = true
  }

  # set {
  #   name  = "installCRDs"
  #   value = "true"
  # }

  # Manifest to create cert-manager service account
  values = [
    "${file("./cert-manager/cert-manager-values.yaml")}"
  ]
}


