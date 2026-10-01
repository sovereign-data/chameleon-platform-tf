# Copy to terraform.tfvars. One entry per workspace; Terraform puts the
# listed Keycloak usernames into ws-<slug>-admins / ws-<slug>-members.
workspaces = {
  cbs-energy = {
    display_name = "CBS energy (open data)"
    admins       = ["alice"]
    members      = ["bob", "carol"]
  }
  team-finance = {
    display_name = "Finance"
    members      = ["dave"]
  }
}
