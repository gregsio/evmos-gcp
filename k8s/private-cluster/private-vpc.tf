# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc-us1"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "private-subnet" {
  name          = "${var.project_id}-private-subnet-${var.region}"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.0.0.0/16"
  secondary_ip_range {
    range_name    = "${var.region}-gke-pods"
    ip_cidr_range = "10.1.0.0/16"
  }
  secondary_ip_range {
    range_name    = "${var.region}-gke-services"
    ip_cidr_range = "10.2.0.0/16"
  }
}
