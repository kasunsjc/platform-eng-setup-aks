# Terraform state bootstrap

This root creates a dedicated state resource group, a storage account, and
private `bootstrap` and `dev` containers. The initial local state is sensitive:
keep it outside version control and migrate it to the bootstrap container as
soon as the storage account is available.

The demo state account accepts traffic from all public networks. Entra
authentication and Blob data-plane RBAC remain required, and shared keys and
anonymous Blob access are disabled. This removes the IP firewall boundary for
sensitive state and increases the impact of compromised credentials. This is a
demo security exception, not a production pattern. A separate enterprise or
production state account needs private connectivity, private DNS, isolated
access controls, and tested recovery. This root does not implement that path.

Before running Terraform, establish:

- A dedicated subscription or resource-group boundary and the required Azure
  resource-management permissions.
- Microsoft Entra authentication and the Blob data-plane role needed to create
  containers and use the backend. Shared-key authentication is disabled.
- Region, unique storage account name, organization tags, state replication and
  soft-delete retention matched to recovery requirements, and recovery owners.

Bootstrap and development use separate containers. Scope Blob data-plane access
to the relevant container; use a separate state account and access boundary for
production. Blob versioning, soft delete, and leases support recovery and
locking, but do not replace a tested recovery procedure.

## Initial local-state sequence

1. In a protected working directory outside the repository, make a copy of this
   root and remove the `backend "azurerm" {}` block **from that copy only**.
   The copy initially uses Terraform's local backend. Do not copy its state or
   credential-bearing files back into Git.
2. Copy `terraform.tfvars.example` to `terraform.tfvars` in that working
   directory and supply the required values. Authenticate with Azure CLI.
3. Run `terraform init`, `terraform fmt -check`, `terraform validate`, and
   review `terraform plan`. `terraform init -backend=false` in the repository
   root is for static validation, not a local-state bootstrap.
4. After approval, apply the copied root using local state. Restrict and protect
   that state file; it must never be committed.
5. Restore the `backend "azurerm" {}` block in the copy, copy
   `backend.hcl.example` to `backend.hcl`, fill in the storage account name,
   then run `terraform init -migrate-state -backend-config=backend.hcl`.
   Confirm the state is in the private bootstrap container before securely
   removing local copies. Continue maintaining the deployed resources from
   the repository root configured against that same remote backend.
6. Configure the development backend with its separate `dev` container and key.
   Verify that authorized demo clients can use the public endpoint and
   unauthorized principals are denied.

For CI, use GitHub Actions OIDC and Entra data-plane RBAC. Do not configure
client secrets, account keys, or broad subscription roles. OIDC federation alone
does not grant Azure permissions; review and grant narrowly scoped roles in a
separate authorization step.
