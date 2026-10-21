---
name: azure-terraform-delivery
description: Implement or review Terraform for Azure networking, identity, state, ACR, Key Vault, and AKS. Use for infrastructure modules, environment roots, bootstrap, and Terraform CI changes.
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
   Keep the AKS API private and local accounts disabled. Scope RBAC narrowly;
   verify private runner reachability instead of opening public access.
6. Separate Azure provisioning from Argo CD bootstrap. Do not configure Kubernetes
   providers against an endpoint that is still unknown in the initial apply.
   Avoid creating resources already reconciled by Argo CD.
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
