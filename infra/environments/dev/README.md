# Development foundation

This root creates only the first non-production foundation: a resource group,
VNet with node and reserved private-endpoint subnets, a Premium ACR
registry, an RBAC-enabled Key Vault, and a GitHub environment OIDC
identity. It does not create AKS, configure Argo CD, grant Azure roles, or deploy
any resources.

The demo ACR and Key Vault endpoints allow requests from all public networks.
Entra authentication and RBAC still apply, but there is no source-IP network
boundary. State bootstrap has the same exception. This increases exposure,
especially if an identity is compromised. Use only synthetic demo data, record
the exception owner and expiry, and never reuse this root for production.
Key Vault uses soft delete and purge protection. No private endpoints or private
DNS zones are created by this root.

## Prerequisites and authorization

- Complete the README decisions for subscription, region, tags, address
  spaces, and cost.
- Create the state account with `infra/bootstrap/state` and configure this root
  to use its separate `dev` container.
- Future AKS nodes and runners do not need IP allowlists for these three
  endpoints, but they still need appropriate identities and scoped permissions.
  Their connectivity and authorization have not been tested.
- Authenticate through Entra ID. For local validation/application, use Azure CLI
  login. For GitHub Actions, configure OIDC using the created managed identity,
  a protected GitHub environment, and `ARM_USE_OIDC=true`; do not store client
  secrets or storage keys.
- The identity created here has a repository/environment-scoped federated
  credential but **no Azure role assignments**. OIDC proves identity, not
  authorization. Define and approve the minimum permissions for plan/apply and
  assign them at the narrowest resource scope in a separate reviewed change.
- Ensure the operator and runner have the required Azure resource-management
  permissions and Blob data-plane access to the relevant state container.

## Validation and backend setup

Copy `terraform.tfvars.example` to `terraform.tfvars`, supply all required
non-secret values, and copy `backend.hcl.example` to `backend.hcl`. Initialize
with the backend config from a trusted runner that can reach the state endpoint:

```sh
terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan
```

Review the plan, role scopes, network ranges, and expected costs before applying.
If an earlier version was deployed, this change proposes deleting its private
endpoints and DNS zones; review any consumers and obtain explicit approval
before applying. Enterprise/production requires separate state, private
endpoints and DNS, private AKS, private runner access, and verified service
connectivity. No AKS or GitOps bootstrap is included in this phase.
