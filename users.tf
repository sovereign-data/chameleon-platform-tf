# Demo people. Passwords are generated and only exposed as a sensitive
# output; Keycloak keeps them after create (rotate there). Workspace access
# comes from var.workspaces admins/members, not from here.
variable "demo_users" {
  type = map(object({
    first_name = string
    last_name  = string
    roles      = optional(list(string), [])
  }))
  default = {
    anna = { first_name = "Anna", last_name = "Engineer" }
    bas  = { first_name = "Bas", last_name = "Analyst" }
  }
}

resource "random_password" "demo" {
  for_each = var.demo_users
  length   = 20
  special  = false
}

resource "chameleon_user" "demo" {
  for_each   = var.demo_users
  username   = each.key
  email      = "${each.key}@demo.sovereign-data.org"
  first_name = each.value.first_name
  last_name  = each.value.last_name
  password   = random_password.demo[each.key].result
  roles      = each.value.roles
}

output "demo_user_passwords" {
  sensitive = true
  value     = { for u, p in random_password.demo : u => p.result }
}
