output "namespace" {
  description = "Jenkins namespace"
  value       = var.namespace
}

output "release_name" {
  description = "Helm release name for Jenkins"
  value       = helm_release.jenkins.name
}
