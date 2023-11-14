# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

# Uncomment and use this ressource to fetch your Dedicated Interconnect
# data "google_compute_subnetwork" "subnetwork" {
#   name    = var.interconnect_subnet
#   project = var.project_id
#   region  = var.region
#    depends_on = [
#     module.vpc
#   ]
#  }

locals {
  cluster_type = "private"
}


module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = var.project_id
  name                       = "${local.cluster_type}-cluster-${var.cluster_name_suffix}"
  region                     = var.region
  zones                      = var.zones
  network                    = var.network
  subnetwork                 = var.subnetwork
  ip_range_pods              = var.ip_range_pods
  ip_range_services          = var.ip_range_services
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  enable_private_endpoint    = false # can be switched to true if you want access from a Dedicated Interconnect
  enable_private_nodes       = true
  master_global_access_enabled = false
  add_cluster_firewall_rules  = true
  grant_registry_access       = true
  master_authorized_networks = [
    # Uncomment to authorized control plane acccess from your Dedicated Interconnect
    # {
    #   cidr_block   = data.google_compute_subnetwork.subnetwork.ip_cidr_range
    #   display_name = "VPC"
    # },
    {
      cidr_block = "${var.controller_public_ip}"
      display_name = "controller"
    },
    {
      cidr_block = "${var.argocd_k8s_master_ip}"
      display_name = "argocd k8s cluster master IP"
    },
  ]

  node_pools = [
    {
      name                      = "default-node-pool"
      machine_type              = "n1-standard-8"
    #  machine_type              = "e2-medium"
      node_locations            = "us-central1-a"
      min_count                 = 1
      max_count                 = 1
      local_ssd_count           = 0
      spot                      = false
      disk_size_gb              = 100
      disk_type                 = "pd-standard" ## switch to SSDs when ready to launch validator. I/O intensive workload.
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

   depends_on = [module.vpc]
}
