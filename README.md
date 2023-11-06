# evmos-gcp
Google Kubernetes Engine (GKE) clusters on GCP, utilizing ArgoCD for multi-cluster application management, setting up monitoring, crafting a robust CI pipeline, and public exposure of services.



# Prerequisites

## Install Terraform
Download and install Terraform from the official website: https://www.terraform.io/downloads.html

## Google Cloud Platform Setup
Create a Google Cloud Project, if you don't have one already.
Enable the Kubernetes Engine API for your project.
Create a Service Account with the necessary permissions for Terraform to manage resources in your GCP project.

## Configure Gcloud SDK

Install https://cloud.google.com/sdk/gcloud/
Install gke-gcloud-auth-plugin for use with kubectl by following the instructions (here)[https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke]

## Install Kubectl, Gcloud CLI, gke-gcloud-auth-plugin & Argo CLI
```bash
sudo apt-get install apt-transport-https ca-certificates gnupg curl sudo
echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt cloud-sdk main" \
    | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

sudo apt-get update
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
sudo apt-get install kubectl
```
Configure kubectl
[GCloud doucentation on kubctl auth changes](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke?hl=en)

```bash
gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --region $(terraform output -raw region)
```
Install ArgoCLI: https://github.com/argoproj/argo-workflows/releases/latest

# GKE Cluster Creation on GCP

Creates a VPC and subnet for the GKE cluster. This is  highly recommended to keep GKE clusters isolated.
Terraform apply
```bash
cd k8s/public-cluster
terraform init
terraform apply
```

Verify with gcloud CLI
```bash
gcloud container clusters describe $(terraform output -raw kubernetes_cluster_name) --region europe-west1 --format='default(locations)'
```
Expected output should be similar to this
    locations:
    - europe-west1-b
    - europe-west1-c
    - europe-west1-d


## Install Kubernetes Dashboard (optional)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

Use kubectl port forwaring to access the Web UI

## Admin user setup
```bash
kubectl apply -f kubernetes-dashboard-admin.rbac.yaml
```

Generate Token
```bash
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep service-controller-token | awk '{print $1}')
```

# ArgoCD Instalation

Run Terraform code in argocd directory
```bash
cd argocd
terraform init
terraform apply
```

## Config ArgoCD API access (for test/demo only)

Openning ArgoCD to Public LoadBalancer with no Access Control is a security risk
Use for short term demonstration purpose or use port forwarding instead !
```bash
gcloud auth login
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
kubectl get all -n argocd
```

## Test ArgoCD setup with a basic Nginx app

Let's use a simple Nginx Deployment Test on ArgoCD's GKE cluster
Fetch argocd password and login to the cli

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
Create a new ArgoCD deployment of test nginx app
```bash
argocd app create argocd-demo --repo https://github.com/gregsio/argocd-demo --path yamls --dest-namespace default --dest-server https://kubernetes.default.svc
```

# Creation of a private GKE cluster
```bash
cd k8s/private-cluster
terraform init
terraform apply
```

# Multi-Cluster Management with ArgoCD

## Add a New GKE Private Cluster to ArgoCD

```bash
gcloud container clusters list --region=us-central1
kubectl config get-contexts
argocd cluster add gke_evmos-gcp_us-central1_gke-private-us
argocd cluster list
```
 the ouput should show both cluster as follow

        SERVER                          NAME                                      VERSION      STATUS      MESSAGE  PROJECT
        https://34.16.114.206           gke_evmos-us-central1_gke-private-us1       1.27     Successful
        https://kubernetes.default.svc  in-cluster                                  1.27     Successful

## Install the Nginx test App on the private GKE cluster

```bash
    argocd app create argocd-demo
        \--repo https://github.com/gregsio/argocd-demo
        \--path yamls
        \ --dest-namespace default
        \--dest-server https://34.16.114.206
```
# Monitoring Setup

## Kubernetes Cluster Monitoring

Clone kube-prometheus

```bash
git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus
```
Install Promotheus & Graphana in a `monitoring` namespace
```bash
kubectl apply --server-side -f manifests/setup
kubectl wait \\n\t--for condition=Established \\n\t--all CustomResourceDefinition \\n\t--namespace=monitoring
kubectl apply -f manifests/
```

## Access Grafana or Promotheus WEB UI

Access via port forwarding:

```bash
kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
kubectl --namespace monitoring port-forward svc/grafana 3000
```
# Deployement of the Evmos Application

The Evmos/testnet directory contains a custom set of scripts and a Dockerfile to configure an *Evmos* testnet node using any of the following approaches:

- Fecthing Genesis file (default setup)
- Snapshot sync
- State sync

Update the k8s/manifests/statfulset.yaml if you want to use a different script at startup
The 3 scripts are in the container's PATH.


## Use ArgoCD for Continuous Deployment(CD Pipeline)

ArgoCD continuously monitors the git repository for any changes that happen and then pulls the changes. It compares the current state of the deployed application with the desired state in the git repository and then applies the changes by automatically deploying the manifest on the GKE cluster.


Create the *Evmos* application in ArgoCD via ArgoCD CLI

```bash
argocd app create evmos \
    --repo https://github.com/gregsio/evmos-gcp \
    --path evmos/manifests \
    --revision dev \
    --dest-namespace evmostestnet \
    --dest-server  https://kubernetes.default.svc
```

Deployement Workflow:

0. Fork this repo
1. Build the Docker image using the provided Dockerfile
2. Push it to a remote Docker repository
3. Update the *image* reference in the *manifests/statefulset.yaml* and commit
4. Sync the *Evmos* application with ArgoCD UI

You can also activate ArgoCD auto sync, so k8s manifets are applied.

To automate the steps detailed in this section keep reading...

# Continuous Integration (CI) Pipeline

- The Infrastructure code (k8s directory) such as VPCs setup and GKE clusters setup is automated using *TerraformCloud*.

- The Continuous Integration of the Evmos validator application is done using *Google CloudBuild*.

Continuous Integration WorkFlow

When a developper make a change to the code, and pushes it to the application repository,
Cloud build then invokes triggers either manually or automatically by the events on the repository such as pushes or pull requests.

Once the trigger gets invoked by any events, cloud build then executes the instructions written in the build config file (cloudbuild.yaml) such as building the docker image from Dockerfile provided and pushing it to the artifact registry configured.
Once the image with the new tag got pushed to the registry, it will get updated in the Kubernetes manifest repository.


## Evmos Validator CI Pipeline
This section automates the steps outlined in "Semi-automated Deployement Workflow".
2 CI files are provided to achieve this:
- evmos/manifests/statefulset.yaml.tpl
- evmos/testnet/cloudbuild.yaml

Prerequistes:
- Move the code under evmos/testnet to a new repository (hard requirement)

Confgure CloudBuild [...]

## K8s Clusters CI Pipeline
With Terrform Cloud the Terrafrom state files will be safely stored encrypted at rest.
[...]


# Evmos's documentation:

- [Minimum Requirements](https://docs.evmos.org/validate/#minimum-requirements)
- [Run a Validator](https://docs.evmos.org/validate/setup-and-configuration/run-a-validator)
- [Common Problems](https://docs.evmos.org/validate/setup-and-configuration/run-a-validator#common-problems)
- [Testnet Documentation](https://docs.evmos.org/validate/testnet)
- [Testnet Faucet](https://faucet.evmos.dev/)
