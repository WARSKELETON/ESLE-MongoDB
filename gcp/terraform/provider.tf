provider "google" {
  # Create/Download your credentials from:
  # Google Console -> "APIs & services -> Credentials"
  credentials = file("./test-kubernetes-327118.json")
  project     = var.project_id
  region      = var.region
}


provider "kubernetes" {
  host = "https://${google_container_cluster.primary.endpoint}"

  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}
