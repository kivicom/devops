resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.6.7"

  values = [
    file("${path.module}/values.yaml")
  ]
}

resource "helm_release" "argo_cd_apps" {
  name      = "argo-apps"
  namespace = kubernetes_namespace.argocd.metadata[0].name
  chart     = "${path.module}/charts"

  values = [
    file("${path.module}/charts/values.yaml")
  ]

  # Прокидываем переменные в values через set
  set {
    name  = "repositories[0].url"
    value = var.apps_repo_url
  }

  set {
    name  = "applications[0].path"
    value = var.apps_repo_path
  }

  set {
    name  = "applications[0].targetRevision"
    value = var.apps_target_rev
  }

  depends_on = [helm_release.argo_cd]
}
