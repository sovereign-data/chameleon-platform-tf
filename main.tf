# One workspace = one catalog (ws_<slug>) + ws-<slug>-{admins,members} groups.
resource "chameleon_workspace" "cbs" {
  slug         = var.workspace_slug
  display_name = "CBS energy (open data)"
  description  = "Dutch dwelling energy use x consumer tariffs — dlt + dbt + Airflow demo."
}

resource "chameleon_workspace_member" "members" {
  for_each       = toset(var.workspace_members)
  workspace_slug = chameleon_workspace.cbs.slug
  username       = each.value
}

# dlt lands parquet here; dbt bronze reads it with SQE read_parquet().
resource "chameleon_storage_bucket" "landing" {
  name = var.landing_bucket
}

# The backend clones the dbt repo through this (method B: dbt in Chameleon).
resource "chameleon_connection" "github" {
  name           = "github-sovereign-data"
  type           = "github"
  url            = var.dbt_repo_url
  credentials    = var.github_pat
  workspace_slug = chameleon_workspace.cbs.slug
}

resource "chameleon_project" "cbs_dbt" {
  kind           = "dbt"
  name           = "cbs-energy-dbt"
  repo_url       = var.dbt_repo_url
  default_branch = "main"
  namespace      = "cbs_gold"
  connection_id  = chameleon_connection.github.id
  workspace_slug = chameleon_workspace.cbs.slug
}

# Airflow's identity in this workspace: client_credentials, write on its catalog.
# Used by both DAG methods (provider API calls and dbt-trino -> SQE).
resource "chameleon_service_principal" "airflow" {
  name            = "sp-airflow-${var.workspace_slug}"
  served_catalogs = [chameleon_workspace.cbs.primary_catalog]
  mode            = "write"
  workspace_slug  = chameleon_workspace.cbs.slug
}
