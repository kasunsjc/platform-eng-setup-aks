# Repository instructions

## Scope and source of truth

- Read `README.md` before changing the platform design. It is the architecture,
  implementation sequence, and acceptance-gate source of truth.
- This repository contains a plan, Copilot guidance, and initial Terraform
  foundation code, but no deployed infrastructure. Do not describe proposed
  paths, commands, or resources as deployed or tested without verifying them.
- Prefer Azure-managed services, AKS, and Terraform as selected in the plan.
  Retain open-source tools for documented gaps, not duplicate managed capabilities.
  Explain licensing and operational trade-offs; do not label current Terraform
  releases or managed Azure services as OSI-approved open source.
- Keep changes focused. Do not provision resources when asked only for a plan.
- Use the AKS Labs source links and adaptation decisions in `README.md` when
  improving platform patterns. Treat lab commands as examples, not approved
  production defaults; verify current support and cite the specific source used.
  Preserve Terraform ownership and Azure-managed defaults rather than silently
  introducing CAPZ, ASO, kro, or a new management cluster.

## Git workflow

- Work on a dedicated feature branch, never directly on `main` or the default
  branch. If already on a task branch, keep using it; otherwise create a new
  branch before edits or commits.
- Never commit credentials, Terraform state, saved plans, kubeconfigs, secret
  values, or credential-bearing variable files. Scan changed files for secrets.
- Explain changes and validation in the pull request, including unrun checks and
  required approvals. Never claim that static validation proves deployment.

## Infrastructure and security

- Follow the proposed environment/module boundaries as implementation is added.
  Isolate production state, identities, and approvals from non-production.
- Pin Terraform/provider/module/chart versions and commit provider lock files.
  Use Azure Blob state with Entra authentication and locking.
- Prefer OIDC federation for CI and AKS Workload Identity for pods. Use
  least-privilege scoped RBAC; never introduce long-lived client secrets or
  public AKS API access as a CI connectivity workaround.
- Enterprise and production AKS clusters must use a private API and private
  connectivity. A separately isolated, non-production demo may use a public
  AKS API solely for direct laptop access, with explicit approved source IP
  ranges, Entra authentication, local accounts disabled, and least-privilege
  access. Do not allow unrestricted API access or use this as a CI workaround.
- Treat the demo's public access as a documented security exception, not an
  enterprise pattern. Use synthetic data, record ownership and expiry, and
  document the private networking, DNS, access, and bootstrap changes needed
  before enterprise use. The isolated demo allows all public networks to reach
  ACR, Key Vault, and Terraform state without IP allowlists; enforce Entra
  authentication and least privilege, and document the added exposure.
  Other demo endpoints retain their own restrictions. Do not expose
  unauthenticated administrative interfaces.
- Bootstrap private connectivity and state before deploying a private AKS cluster.
  Separate Azure infrastructure provisioning from Argo CD bootstrap.
- Terraform owns Azure resources, monitoring, backup, policy, and managed add-on
  configuration. Azure owns objects installed by those add-ons/extensions.
  Argo CD owns applications and remaining in-cluster components after bootstrap.
  Never give competing reconcilers ownership of one object.
- Prefer managed Prometheus, Azure Managed Grafana, Azure Monitor alerts/Action
  Groups, Container Insights/Log Analytics, and Application Insights with Azure
  Monitor OpenTelemetry. Do not install self-hosted equivalents by default.
- Prefer Azure Backup for AKS, Azure Policy, Defender for Containers, and Azure
  Cost Management/AKS cost analysis. Validate coverage; retain database-native
  backups, CI scanning/SBOM/signing, and Kyverno signature verification or gaps.
- Reference Key Vault secrets using the AKS Secrets Store CSI Driver rather than
  embedding values. Justify ESO or Kubernetes Secret synchronization, restrict
  readers/backups, and test rotation plus application reload.
- Evaluate Application Gateway for Containers against networking, Gateway API,
  region, and feature requirements before adoption. Azure DNS and Key Vault
  certificates still need supported issuance/renewal/controller integration.
- Retain Argo CD and later Backstage; Flux is an alternative, not a second
  reconciler. Record operational cost and approval for open-source exceptions.
- Bridge approved Terraform output to separate GitOps bootstrap using non-secret,
  allowlisted metadata and runtime authentication. Protect root applications,
  AppProjects, ApplicationSet generators, and cluster registration from team edits.
- Validate generated destinations, child readiness, and parent/selector deletion
  behavior before automation. Sync waves alone are not cross-application readiness
  guarantees; review finalizers/pruning rather than copying lab cleanup commands.
- Use immutable image digests, signature trust rules, restricted pod security,
  network policies, and documented exceptions. Do not silently weaken controls.
- Keep production applies behind explicit approval. Never run privileged workflows
  on untrusted pull-request code; pin Actions to reviewed commit SHAs.

## Validation

- Inspect existing tooling before running commands. Terraform foundation roots
  exist, but no automated test suite is configured; add checks alongside
  implementation.
- For documentation-only edits, check consistency, local links, skill metadata,
  and accidental secrets. Do not deploy Azure resources to validate prose.
- Verify managed-service region/SKU/GA status, Terraform support, private
  ingestion/query/data-source paths, RBAC, collection/retention costs, backup
  coverage, and restore restrictions before production. Report unverified claims.
- Once Terraform exists, use formatting, per-root initialization/validation,
  configured lint/security checks, and reviewed environment-specific plans.
- Once GitOps manifests exist, lint/render charts and overlays, validate schemas,
  and test policies before integration checks in non-production.
- Report checks actually run and their results. Request approval before applies,
  destructive operations, production changes, or actions that incur cloud costs.

## Reusable skills

Use the relevant `SKILL.md` under `.github/skills/` for platform planning,
Terraform delivery, or AKS GitOps changes. Skills supplement these instructions
and do not grant permission to deploy or bypass approvals.
