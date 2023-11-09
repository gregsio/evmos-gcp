
module "peering1" {
  source        = "terraform-google-modules/network/google//modules/network-peering"
  version       = "~> 7.0"
  local_network = "${var.local_network}"
  peer_network  = "${var.peer_network}"
}
