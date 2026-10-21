# Repository instructions

## Scope and source of truth

- Read `README.md` before changing the platform design. It is the architecture,
  implementation sequence, and acceptance-gate source of truth.
- This repository currently contains a plan and Copilot guidance, not deployed
  infrastructure. Do not describe proposed paths, commands, or resources as
  existing or tested without verifying them.
- Prefer Azure-managed services, AKS, and Terraform as selected in the plan.
  Retain open-source tools for documented gaps, not duplicate managed capabilities.
  Explain licensing and operational trade-offs; do not label current Terraform
  releases or managed Azure services as OSI-approved open source.
- Keep changes focused. Do not provision resources when asked only for a plan.

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
- Use immutable image digests, signature trust rules, restricted pod security,
  network policies, and documented exceptions. Do not silently weaken controls.
- Keep production applies behind explicit approval. Never run privileged workflows
  on untrusted pull-request code; pin Actions to reviewed commit SHAs.

## Validation

- Inspect existing tooling before running commands. No infrastructure or
  automated test suite exists yet; add checks only alongside implementation.
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
