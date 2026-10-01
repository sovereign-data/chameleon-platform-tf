# chameleon-platform-tf

Terraform for the tenant side of a Chameleon platform (the platform itself is
the data-platform-operator's `DataPlatform` CR). Creates everything the CBS
workloads need:

| Resource | For |
|---|---|
| `chameleon_workspace.ws[*]` + `chameleon_workspace_{admin,member}` | one per `var.workspaces` entry: catalog `ws_<slug>`, groups `ws-<slug>-{admins,members}` filled from the lists |
| `chameleon_storage_bucket.landing` | dlt landing bucket `cbs-landing` |
| `chameleon_connection.github` + `chameleon_project.cbs_dbt` | backend-run dbt (method B) from `chameleon-cbs-dlt-dbt` |
| `chameleon_service_principal.airflow` | Airflow's client-credentials identity, write on the workspace catalog |

## Who is in which workspace

The platform authorizes on Keycloak groups `ws-<slug>-admins` / `ws-<slug>-members`
(token `groups` claim). Edit `var.workspaces` (see `example.tfvars`) and open a PR —
that is the whole process:

```hcl
workspaces = {
  cbs-energy = { display_name = "CBS energy", admins = ["alice"], members = ["bob"] }
}
```

When Okta is connected, people move to Okta groups `CHM-WS-<slug>-Admins|Members`
and Keycloak maps them at every login (see the operator's `docs/identity.md`); keep
only break-glass local accounts in these lists. Service principals are bound to a
workspace by `workspace_slug`, never by group.

## Provider

Not on the public registry. Either build it and use `dev_overrides`:

```hcl
# ~/.terraformrc
provider_installation {
  dev_overrides { "registry.terraform.io/schubergphilis/chameleon" = "/path/to/data-platform-terraform-provider" }
  direct {}
}
```

…or download the GitLab generic package `data-platform-terraform-provider` (≥ the release
with `chameleon_service_principal`) into a filesystem mirror.

## Run

```bash
export CHAMELEON_ENDPOINT=https://app.test.sovereign-data.org
export CHAMELEON_OIDC_ENDPOINT=https://keycloak.test.sovereign-data.org
export CHAMELEON_REALM=chameleon CHAMELEON_CLIENT_ID=polaris-frontend-client
export CHAMELEON_USERNAME=chameleon-admin
export CHAMELEON_PASSWORD=$(kubectl -n keycloak get secret chameleon-admin-secret -o jsonpath='{.data.password}' | base64 -d)
# optional: export TF_VAR_github_pat=...   (only for a private dbt repo)

terraform init && terraform apply
```

## Wire Airflow

```bash
# connection + variables (until the Vault secrets backend lands in the operator)
kubectl -n airflow exec deploy/airflow-scheduler -- airflow connections add chameleon_default \
  --conn-json "$(terraform output -raw airflow_connection)"
kubectl -n airflow exec deploy/airflow-scheduler -- airflow variables set cbs_catalog "$(terraform output -raw catalog)"
kubectl -n airflow exec deploy/airflow-scheduler -- airflow variables set cbs_dbt_project_id "$(terraform output -raw dbt_project_id)"
```

Platform side (DataPlatform CR) — once, by the platform admin:

```yaml
spec:
  airflow: {enabled: true}
  valueOverrides:
    sqe: {extraTvfPrefixes: ["s3://cbs-landing/"]}
    airflow:
      airflow:
        dags:
          gitSync: {enabled: true, repo: https://github.com/sovereign-data/chameleon-airflow-e2e.git, branch: main, subPath: dags}
```

State holds the service principal's client secret — use an encrypted backend
for anything beyond a demo.
