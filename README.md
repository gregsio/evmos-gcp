# evmos-gcp
Google Kubernetes Engine (GKE) clusters on GCP, utilizing ArgoCD for multi-cluster application management, setting up monitoring, crafting a robust CI pipeline, and public exposure of services.


## Prerequisites

### Install Terraform:
        Download and install Terraform from the official website: https://www.terraform.io/downloads.html

### Google Cloud Platform Setup:
        Create a Google Cloud Project, if you don't have one already.
        Enable the Kubernetes Engine API for your project.
        Create a Service Account with the necessary permissions for Terraform to manage resources in your GCP project.

### Configure GCLOUD Authentication:
        <!-- Configuration of workload identity federation for Terraform Cloud/Enterprise workflows (RECOMMENDED for TerraformCloud production setup)
        - https://cloud.google.com/iam/docs/workload-identity-federation -->

        Install gke-gcloud-auth-plugin for use with kubectl by following ( Recomended for DEV & STAGING environment)
        - https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke



#### Install Kubectl, gcloud cmd-line &  gke-gcloud-auth-plugin

        sudo apt-get install apt-transport-https ca-certificates gnupg curl sudo

        echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        sudo apt-get update

        sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
        sudo apt-get install kubectl

        Configure kubectl
        https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke?hl=en

        gcloud container clusters get-credentials $(terraform output -raw kubernetes_cluster_name) --region $(terraform output -raw region)

    Install ArgoCLI: https://github.com/argoproj/argo-workflows/releases/latest


## Provision a GKE Cluster

Terraform configuration files to provision an GKE cluster on GCP.  [Provision a GKE Cluster tutorial](https://developer.hashicorp.com/terraform/tutorials/kubernetes/gke)

Creates a VPC and subnet for the GKE cluster. This is  highly recommended to keep GKE clusters isolated.

Run:
 terraform init
 terraform apply

Verify:
    gcloud container clusters describe $(terraform output -raw kubernetes_cluster_name) --region europe-west1 --format='default(locations)'
    locations:
    - europe-west1-b
    - europe-west1-c
    - europe-west1-d


### Install Kubernetes Dashboard (optional)

        kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
        namespace/kubernetes-dashboard created
        serviceaccount/kubernetes-dashboard created
        service/kubernetes-dashboard created
        secret/kubernetes-dashboard-certs created
        secret/kubernetes-dashboard-csrf created
        secret/kubernetes-dashboard-key-holder created
        configmap/kubernetes-dashboard-settings created
        role.rbac.authorization.k8s.io/kubernetes-dashboard created
        clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
        rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
        clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
        deployment.apps/kubernetes-dashboard created
        service/dashboard-metrics-scraper created
        deployment.apps/dashboard-metrics-scraper created

        kubectl proxy

        #Admin user setup
         kubectl apply -f https://raw.githubusercontent.com/hashicorp/learn-terraform-provision-gke-cluster/main/kubernetes-dashboard-admin.rbac.yaml

        #Generate Token
         kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep service-controller-token | awk '{print $1}')


# Install Argo CD

        cd argocd
        terraform init
        terraform apply

### Install Argo CD CLI


    gcloud auth login

    ### Openning ArgoCD to Public LoadBalancer with no Access Control is a security risk
    ## Use for short term demonstration purpose or use port forwarding instead !
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    kubectl get all -n argocd


#### Simple nginx app deployment test on ArgoCD's GKE cluster


    ##Fetch argocd password and login to the cli
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

    argocd app create argocd-demo --repo https://github.com/gregsio/argocd-demo --path yamls --dest-namespace default --dest-server https://kubernetes.default.svc


### Add the previously deployed GKE private cluster to ArgoCD
    gcloud container clusters list --region=us-central1
    kubectl config get-contexts
    argocd cluster add gke_evmos-gcp_us-central1_gke-private-us

    argocd cluster list  ##Should show both cluster

        SERVER                          NAME                                      VERSION  STATUS      MESSAGE  PROJECT
        https://34.16.114.206           gke_evmos-gcp_us-central1_gke-private-us  1.27     Successful
        https://kubernetes.default.svc  in-cluster                                1.27     Successful

#### Install test App on the private GKE cluster
    argocd app create argocd-demo --repo https://github.com/gregsio/argocd-demo --path yamls --dest-namespace default --dest-server https://34.16.114.206



## Easy to operate end-to-end Kubernetes cluster monitoring

### Clone
    git clone https://github.com/prometheus-operator/kube-prometheus.git
    cd kube-prometheus

### Install
    kubectl apply --server-side -f manifests/setup
    kubectl wait \\n\t--for condition=Established \\n\t--all CustomResourceDefinition \\n\t--namespace=monitoring
    kubectl apply -f manifests/

### Profit
    kubectl --namespace monitoring port-forward svc/prometheus-k8s 9090
    kubectl --namespace monitoring port-forward svc/grafana 3000


## Deploy Evmos APP

    #build Docker image
    #push it to a remote repo

    #deploy via Argo CD

    argocd app create evmos --repo https://github.com/gregsio/evmos-gcp --path evmos --revision dev --dest-namespace default --dest-server  https://kubernetes.default.svc
