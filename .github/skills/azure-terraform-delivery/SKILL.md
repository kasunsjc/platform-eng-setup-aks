---
name: azure-terraform-delivery
description: Implement or review Terraform for Azure networking, identity, state, AKS, managed monitoring, backup, and policy. Use for infrastructure modules, environment roots, bootstrap, and Terraform CI changes.
---

# Azure Terraform delivery

1. Read `README.md`, repository instructions, and the affected root/module files.
   If the proposed `infra/` structure does not exist, say so and create only the
   pieces explicitly requested. Work on a dedicated feature branch.
2. Establish the environment, subscription, backend key, identity permissions,
   private endpoint/DNS dependencies, and bootstrap order before changing code.
3. Use reusable Azure modules and separate environment roots/state. Declare
   version constraints, typed inputs, validation, useful non-secret outputs,
   consistent naming/tags, and provider lock files.
4. Use Entra-authenticated Azure Blob state with locking, recovery controls, and
   environment isolation. Do not put credentials, secret values, state, saved
   plans, kubeconfigs, or credential-bearing variable files in Git. Sensitive
   Terraform attributes can still be stored in state.
5. Prefer federated OIDC for CI and managed/workload identities for Azure access.
   Keep enterprise and production AKS APIs private and disable local accounts.
   For an isolated non-production demo only, a public AKS API may be used for
   direct laptop access with explicitly approved source IP ranges, Entra
   authentication, and a documented security exception. Do not use public API
   access as a CI connectivity workaround. Scope RBAC narrowly; verify private
   runner reachability for private clusters. Demo ACR, Key Vault, and state
   endpoints allow all public networks without IP allowlists as a documented
   exception. Retain Entra authentication and least privilege; document the
   enterprise private alternative.
6. Separate Azure provisioning from Argo CD bootstrap. Do not configure Kubernetes
   providers against an endpoint that is still unknown in the initial apply.
   Own Azure resources and managed add-on/extension configuration in Terraform;
   Azure owns objects installed by those add-ons. Avoid creating resources
   already reconciled by Argo CD, and do not ask Argo CD to own managed objects.
   Include managed Prometheus workspaces, Managed Grafana, Log Analytics,
   Application Insights, collection rules/associations, alerts/Action Groups,
   Azure Backup, Azure Policy, Defender, and cost reporting where requested.
   Verify region/SKU/GA status, provider support, private ingestion/query/data-source
   connectivity, scoped RBAC, telemetry budgets/retention, backup storage coverage,
   and restore restrictions. Do not claim feature support without evidence.
   Enable Key Vault CSI integration without reading secret values into state.
   Evaluate Application Gateway for Containers before adoption; keep DNS and
   certificate lifecycle/controller requirements explicit.
7. Use the repository's configured checks. Once Terraform roots exist, check
   `terraform fmt -check -recursive`, initialize each affected root with
   `terraform init -backend=false`, and run `terraform validate`. Run configured
   TFLint/security checks; disclose missing tools, provider downloads, or checks
   blocked by the environment rather than claiming success.
8. Obtain plans only in a trusted context with scoped backend/cloud access.
   Summarize additions, replacements, deletions, security changes, cost impact,
   and recovery implications. Treat plan artifacts as sensitive.
9. Require approval before apply/destroy or any cloud-cost-incurring action.
   Production applies use a reviewed saved plan tied to the approved commit,
   environment concurrency controls, and a freshness/state check.

## Completion evidence

Report affected environments, checks actually run, remaining assumptions,
whether a plan/apply was authorized and executed, and any required follow-up.
Do not claim resources exist from a successful format or validation check.

## AKS Labs: Terraform-to-GitOps adaptation

Consult the [GitOps/CAPZ/ASO lab](https://github.com/Azure-Samples/aks-labs/blob/main/docs/platform-engineering/aks-capz-aso.md)
and [App of Apps lab](https://github.com/Azure-Samples/aks-labs/blob/main/docs/platform-engineering/app-of-apps.md)
alongside the adaptation contracts in `README.md`. Use their separation and
bootstrap concepts, not their Azure CLI resource creation or operator ownership.

- Define a minimal non-secret output contract: cluster/resource IDs, environment,
  identity references, and approved GitOps repository/path/revision/capabilities.
  Never hand full state, tokens, or kubeconfigs to Git or portal templates.
- Gate separate bootstrap on a completed reviewed apply, the approved API/DNS
  access path (private for enterprise and production), cluster readiness,
  scoped identity authorization, and the managed-object inventory. Test reruns
  and recovery from partial bootstrap in non-production.
- Keep cluster metadata changes under platform review; metadata must not grant
  arbitrary repository, destination, or production deployment access.
- Prefer validated module inputs and approved workflows for self-service instead
  of CAPZ/ASO/kro installation. Any approved ownership migration must identify
  state handoff, the single active owner, drift checks, deletion protection, and
  recovery before either reconciler changes an existing resource.
- Recheck current APIs, versions, and regional support. Do not copy moving lab
  artifact references, broad roles, or cleanup steps into production automation.
