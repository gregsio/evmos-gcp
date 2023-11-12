module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 8.0"

    project_id   = "${var.project_id}"
    network_name = "${var.network}"
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = "${var.subnetwork}"
            subnet_ip             = "172.16.0.48/28"
            subnet_region         = "${var.region}"
            subnet_private_access = "true"
         #  subnet_flow_logs      = "true"
            description           = "Validator node subnet"
        },
    ]

    secondary_ranges = {
            "${var.subnetwork}" = [
            {
                range_name    = "${var.ip_range_services}"
                ip_cidr_range = "10.1.0.0/16"
            },
            {
                range_name    = "${var.ip_range_pods}"
                ip_cidr_range = "10.2.0.0/16"
            },
        ]

   }
}

# Allow Egress access to public Internet trhough NAT gateway
resource "google_compute_router" "router" {
  name    = "validator-router"
  region  = "${var.region}"
  network = "${var.network}"
  depends_on = [ module.vpc ]
}

module "cloud-nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  project_id                         = var.project_id
  region                             = "${var.region}"
  router                             = google_compute_router.router.name
  name                               = "nat-config"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on                         = [ google_compute_router.router ]
}
