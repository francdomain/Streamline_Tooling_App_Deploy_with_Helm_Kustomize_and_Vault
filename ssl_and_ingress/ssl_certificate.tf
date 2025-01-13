# Certificate issuer
resource "kubectl_manifest" "cert_issuer" {
  yaml_body = file("${path.module}/cert-manager/lets-encrypt-issuer.yaml")

  depends_on = [
    null_resource.update_kubeconfig,
    helm_release.cert_manager,
    kubernetes_cluster_role.cert_manager,
    kubernetes_cluster_role_binding.cert_manager_acme_binding,
  ]
}
