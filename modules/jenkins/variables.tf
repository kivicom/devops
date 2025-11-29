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
  default     = "jenkins"
  description = "Namespace for Jenkins"
}
