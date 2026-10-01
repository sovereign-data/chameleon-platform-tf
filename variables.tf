# Who is in which workspace. Terraform fills the Keycloak groups
# ws-<slug>-admins / ws-<slug>-members that the platform authorizes on.
# With Okta, people move to Okta groups instead (docs/identity.md); keep only
# break-glass local accounts here.
variable "workspaces" {
  type = map(object({
    display_name = string
    description  = optional(string, "")
    admins       = optional(list(string), [])
    members      = optional(list(string), [])
  }))
  default = {
    cbs-energy = {
      display_name = "CBS energy (open data)"
      description  = "Dutch dwelling energy use x consumer tariffs — dlt + dbt + Airflow demo."
    }
  }
}

variable "cbs_workspace" {
  description = "Key in var.workspaces that hosts the CBS demo workload."
  type        = string
  default     = "cbs-energy"
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
