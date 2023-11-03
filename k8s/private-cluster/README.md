# Private Zonal Cluster Terraform Setup

This example illustrates how to create a simple private cluster in a single zone.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_name\_suffix | A suffix to append to the default cluster name | `string` | `""` | no |
| ip\_range\_pods | The secondary ip range to use for pods | `any` | n/a | yes |
| ip\_range\_services | The secondary ip range to use for services | `any` | n/a | yes |
| network | The VPC network to host the cluster in | `any` | n/a | yes |
| project\_id | The project ID to host the cluster in | `any` | n/a | yes |
| region | The region to host the cluster in | `any` | n/a | yes |
| subnetwork | The subnetwork to host the cluster in | `any` | n/a | yes |
| zones | The zone to host the cluster in (required if is a zonal cluster) | `list(string)` | n/a | yes |

## Update Inputs In terraform.tfvars
The code is pretty generic, most variable can directly be set in the .tfvars file
A generic VPC confuration is set in private-vpc.tf. Edit as needed.

To provision this example, run the following from within this directory:
- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure