resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress_nginx_controller" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  namespace = kubernetes_namespace.ingress_nginx.metadata[0].name
  timeout   = 600

  # values = [
  #   "${file("values.yaml")}"
  # ]

  values = [
    <<EOF
    controller:
      extraArgs:
        default-ssl-certificate: "vault/tooling.vault.fncdev.online"
    EOF
  ]

  wait   = true
  atomic = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "true"
  }
  set {
    name  = "metrics.enabled"
    value = "true"
  }

}

# The following command will wait for the ingress controller pod to be up, running, and ready
resource "null_resource" "wait_for_ingress_controller" {
  depends_on = [helm_release.ingress_nginx_controller]

  provisioner "local-exec" {
    command = <<-EOF
      kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=600s
    EOF
  }
}
