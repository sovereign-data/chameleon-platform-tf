output "catalog" {
  description = "Airflow Variable cbs_catalog."
  value       = chameleon_workspace.cbs.primary_catalog
}

output "dbt_project_id" {
  description = "Airflow Variable cbs_dbt_project_id."
  value       = chameleon_project.cbs_dbt.id
}

# JSON for AIRFLOW_CONN_CHAMELEON_DEFAULT (or the secrets backend).
# In-cluster URLs: Airflow runs next to the backend and Keycloak.
output "airflow_connection" {
  sensitive = true
  value = jsonencode({
    conn_type = "chameleon"
    host      = "http://backend.backend:8000"
    login     = chameleon_service_principal.airflow.keycloak_client_id
    password  = chameleon_service_principal.airflow.client_secret
    extra = {
      auth_type           = "service_principal"
      keycloak_issuer_url = "http://keycloak-http.keycloak:8080/realms/chameleon"
      workspace           = chameleon_workspace.cbs.slug
    }
  })
}
