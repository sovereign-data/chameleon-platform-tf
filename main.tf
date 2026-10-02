# One workspace = one catalog (ws_<slug>) + ws-<slug>-{admins,members} groups.
resource "chameleon_workspace" "ws" {
  for_each     = var.workspaces
  slug         = each.key
  display_name = each.value.display_name
  description  = each.value.description
}

moved {
  from = chameleon_workspace.cbs
  to   = chameleon_workspace.ws["cbs-energy"]
}

locals {
  memberships = merge([for slug, ws in var.workspaces : {
    for u in ws.members : "${slug}/${u}" => { slug = slug, username = u }
  }]...)
  admins = merge([for slug, ws in var.workspaces : {
    for u in ws.admins : "${slug}/${u}" => { slug = slug, username = u }
  }]...)
  cbs = chameleon_workspace.ws[var.cbs_workspace]
}

resource "chameleon_workspace_member" "member" {
  for_each       = local.memberships
  depends_on     = [chameleon_user.demo]
  workspace_slug = chameleon_workspace.ws[each.value.slug].slug
  username       = each.value.username
}

resource "chameleon_workspace_admin" "admin" {
  for_each       = local.admins
  depends_on     = [chameleon_user.demo]
  workspace_slug = chameleon_workspace.ws[each.value.slug].slug
  username       = each.value.username
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
  workspace_slug = local.cbs.slug
}

resource "chameleon_project" "cbs_dbt" {
  kind           = "dbt"
  name           = "cbs-energy-dbt"
  repo_url       = var.dbt_repo_url
  default_branch = "main"
  namespace      = "cbs_gold"
  connection_id  = chameleon_connection.github.id
  workspace_slug = local.cbs.slug
}

# Airflow's identity in this workspace: client_credentials, write on its catalog.
# Used by both DAG methods: polaris-frontend-client in aud for the Chameleon
# API (provider operators), sqe for dbt-trino straight to SQE.
resource "chameleon_service_principal" "airflow" {
  name            = "sp-airflow-${var.cbs_workspace}"
  served_catalogs = [local.cbs.primary_catalog]
  mode            = "write"
  workspace_slug  = local.cbs.slug
  audience        = ["sqe", "account", "polaris-frontend-client"]
}
