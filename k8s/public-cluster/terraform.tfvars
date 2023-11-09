# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

project_id          = "evmos-gcp"
cluster_name_suffix = "us"
ip_range_pods       = "sentry-pods"
ip_range_services   = "sentry-services"
network             = "evmos-sentry-vpc"
region              = "us-central1"
subnetwork          = "sentry-subnet-us-central1"
zones               = ["us-central1-a", "us-central1-b"]
