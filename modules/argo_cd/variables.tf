variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint"
}

variable "cluster_ca_cert" {
  type        = string
  description = "EKS cluster CA certificate (base64)"
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Namespace for Argo CD"
}

variable "apps_repo_url" {
  type        = string
  description = "Git repo URL with Helm chart (this repo)"
}

variable "apps_repo_path" {
  type        = string
  description = "Path to django-app chart in repo"
}

variable "apps_target_rev" {
  type        = string
  default     = "main"
  description = "Git revision (branch/tag) for Argo CD application"
}
