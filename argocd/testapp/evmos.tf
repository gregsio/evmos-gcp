provider "argocd" {
  server_addr = "http://34.77.174.77"
}

resource "kubernetes_manifest" "evmos_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "evmos"
      namespace = "evmos"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/gregsio/argocd-demo"
        targetRevision = "HEAD"
        path           = "yamls"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }
    }
  }
}
