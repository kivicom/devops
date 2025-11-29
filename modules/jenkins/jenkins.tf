resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "jenkins"
  version    = "13.2.22" # можно не трогать

  values = [
    file("${path.module}/values.yaml")
  ]
}
