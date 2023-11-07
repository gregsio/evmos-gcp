## Evmos testnet

Evmosd Dockerile and coniguration scripts based tharsishq/evmos:v15.0.0-rc2
This is intended to run on Kubernetes (k8s), see manifests directory for more info on the k8s setup.

The steps involved in setting up the CI/CD pipeline are listed below:

1. Setting up the Continuous Integration Pipeline

1.1 Configuring the GitHub repositories.

1.2 Configuring Cloud Build GitHub Trigger

2. Setting up the Continuous Delivery Pipeline

2.1 Configuring the GKE cluster

2.2 Configuring ArgoCD on GKE


Pre-Requisites:

    Two code repositories, one containing application code and the other containing Kubernetes manifest files and deployment templates. Here we have used GitHub repositories for demonstration.
    Cloud build configured with GitHub application code repository to execute a build based on the events in the repository.
    Artifact Registry to store the images built from cloud build.
    A GKE cluster for running the Docker images of the applications and an ArgoCD server used for continuous delivery.


WorkFlow:

1. Continuous Integration(CI Pipeline):

    A Developer makes the changes in the code, fixes the bugs, and pushes it to the application repository.
    Cloud build then invokes triggers either manually or automatically by the events on the repository such as pushes or pull requests.
    Once the trigger gets invoked by any events, cloud build then executes the instructions written in the build config file (cloudbuild.yaml) such as building the docker image from Dockerfile provided and pushing it to the artifact registry configured.
    Once the image with the new tag got pushed to the registry, it will get updated in the Kubernetes manifest repository.

2. Continuous Deployment(CD Pipeline)

    ArgoCD continuously monitors the git repository for any changes that happen and then pulls the changes. It compares the current state of the deployed application with the desired state in the git repository and then applies the changes by automatically deploying the manifest on the GKE cluster.