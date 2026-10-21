# Repository instructions

## Scope and source of truth

- Read `README.md` before changing the platform design. It is the architecture,
  implementation sequence, and acceptance-gate source of truth.
- This repository currently contains a plan and Copilot guidance, not deployed
  infrastructure. Do not describe proposed paths, commands, or resources as
  existing or tested without verifying them.
- Prefer Azure, AKS, Terraform, and the open-source tools selected in the plan.
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
- Terraform owns Azure infrastructure; Argo CD owns platform and workload
  Kubernetes objects after bootstrap. Never give both ownership of one object.
- Reference Key Vault secrets rather than embedding their values. Account for
  ESO-created Kubernetes Secrets, access restrictions, backups, and rotation.
- Use immutable image digests, signature trust rules, restricted pod security,
  network policies, and documented exceptions. Do not silently weaken controls.
- Keep production applies behind explicit approval. Never run privileged workflows
  on untrusted pull-request code; pin Actions to reviewed commit SHAs.

## Validation

- Inspect existing tooling before running commands. No infrastructure or
  automated test suite exists yet; add checks only alongside implementation.
- For documentation-only edits, check consistency, local links, skill metadata,
  and accidental secrets. Do not deploy Azure resources to validate prose.
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
