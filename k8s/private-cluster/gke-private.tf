# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = "evmos-gcp"
  name                       = "gke-private-us"
  region                     = "${var.region}"
  zones                      = ["us-central1-a", "us-central1-b", "us-central1-f"]
  network                    = "${var.project_id}-vpc-us1"
  subnetwork                 = "${var.project_id}-private-subnet-${var.region}"
  ip_range_pods              = "${var.region}-gke-pods"
  ip_range_services          = "${var.region}-gke-services"
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = false
  enable_private_endpoint    = false  // Should be turned to True in production for further isolation.
                                      // indicates that the cluster is managed using the private IP address of the control plane API endpoint.
  enable_private_nodes       = true
  master_ipv4_cidr_block     = "10.50.0.0/28"
  # master_authorized_networks = [{
  #   cidr_block   = "bastion-host-ip-address/28"   // Needs to be a reserved network and is required for private endpoints
  #   display_name = "remote-client-gsaramite"
  # }]
  master_global_access_enabled = true

  node_pools = [
    {
      name                      = "default-node-pool"
      machine_type              = "e2-medium"
      node_locations            = "us-central1-b,us-central1-c"
      min_count                 = 1
      max_count                 = 3
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
      initial_node_count        = 2
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