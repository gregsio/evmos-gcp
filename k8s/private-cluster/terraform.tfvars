# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

project_id            = "evmos-gcp"
cluster_name_suffix   = "us"
ip_range_pods         = "validator-pods"
ip_range_services     = "validator-services"
network               = "evmos-validator-vpc"
region                = "us-central1"
subnetwork            = "validator-subnet-us-central1"
zones                 = ["us-central1-a", "us-central1-b"]
