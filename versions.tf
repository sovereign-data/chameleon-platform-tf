terraform {
  required_version = ">= 1.6"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    chameleon = {
      # Not on the public registry yet: dev_overrides to a local build, or the
      # GitLab generic package (see README).
      source  = "registry.terraform.io/schubergphilis/chameleon"
      version = "~> 0.1"
    }
  }
}

# Auth via env, never in code:
#   CHAMELEON_ENDPOINT=https://app.<domain>  CHAMELEON_OIDC_ENDPOINT=https://keycloak.<domain>
#   CHAMELEON_REALM=chameleon  CHAMELEON_CLIENT_ID=polaris-frontend-client
#   CHAMELEON_USERNAME=chameleon-admin  CHAMELEON_PASSWORD=<vault secret/chameleon/admin>
#   CHAMELEON_CA_CERT_PATH=<internal-ca bundle> (spec.tls=internal-ca without publicTLS)
provider "chameleon" {}
