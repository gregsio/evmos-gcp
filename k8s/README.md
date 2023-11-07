# Terraform K8s setup in GKE
Terraform K8s setup of a public and a private GKE cluster
Requires access to gcloud via oauth




 Use an oauth token, such as this example from a GKE cluster. The google_client_config data source fetches a token from the Google Authorization server, which expires in 1 hour by default.
```json
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}
```
