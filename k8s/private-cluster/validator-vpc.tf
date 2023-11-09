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
