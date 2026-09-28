variable "workspace_slug" {
  type    = string
  default = "cbs-energy"
}

variable "workspace_members" {
  description = "Keycloak usernames added as workspace members."
  type        = list(string)
  default     = []
}

variable "landing_bucket" {
  description = "dlt landing bucket; also add s3://<bucket>/ to the CR's valueOverrides.sqe.extraTvfPrefixes."
  type        = string
  default     = "cbs-landing"
}

variable "dbt_repo_url" {
  type    = string
  default = "https://github.com/sovereign-data/chameleon-cbs-dlt-dbt"
}

variable "github_pat" {
  description = "GitHub PAT (contents:read) for the dbt repo. Empty is fine for a public repo."
  type        = string
  default     = ""
  sensitive   = true
}
