# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

# data "google_compute_subnetwork" "subnetwork" {
#   name    = var.subnetwork
#   project = var.project_id
#   region  = var.region
# }

locals {
  cluster_type = "private-zonal"
}


module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = var.project_id
  name                       = "${local.cluster_type}-cluster${var.cluster_name_suffix}"
  region                     = var.region
  zones                      = var.zones
  network                    = var.network
  subnetwork                 = var.subnetwork
  ip_range_pods              = var.ip_range_pods
  ip_range_services          = var.ip_range_services
  http_load_balancing        = false
  network_policy             = true
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  enable_private_endpoint    = false # turn to true in production environment
  enable_private_nodes       = true
  master_ipv4_cidr_block     = "10.50.0.0/28"
  master_global_access_enabled = true
  add_cluster_firewall_rules  = true
  gateway_api_channel         = "CHANNEL_STANDARD"

  # enable in production.
  # master_authorized_networks = [
  #   {
  #     cidr_block   = data.google_compute_subnetwork.subnetwork.ip_cidr_range
  #     display_name = "VPC"
  #   },
  # ]

  node_pools = [
    {
      name                      = "default-node-pool"
      machine_type              = "n1-standard-8"
      node_locations            = "us-central1-a,us-central1-b"
      min_count                 = 1
      max_count                 = 5
      local_ssd_count           = 0
      spot                      = false
      disk_size_gb              = 10
      disk_type                 = "pd-standard"
      image_type                = "COS_CONTAINERD"
      enable_gcfs               = false
      enable_gvnic              = false
      logging_variant           = "DEFAULT"
      auto_repair               = true
      auto_upgrade              = true
      preemptible               = false
      initial_node_count        = 1
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}