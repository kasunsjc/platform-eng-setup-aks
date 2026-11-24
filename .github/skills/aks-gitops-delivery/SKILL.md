---
name: aks-gitops-delivery
description: Implement or review AKS platform components and workload delivery with Argo CD, Helm, and Kustomize. Use for GitOps manifests, policies, secrets integration, observability, and service onboarding.
---

# AKS GitOps delivery

1. Read `README.md`, repository instructions, and existing manifests. Confirm
   target cluster/environment and ownership. Proposed `platform/` and `templates/`
   paths may not exist yet; add only requested implementation.
2. Separate Terraform-owned Azure resources and the one-time Argo CD bootstrap
   from GitOps-owned application manifests and remaining in-cluster components.
   Azure owns objects installed by Terraform-enabled managed add-ons/extensions;
   exclude them from Argo CD. Never reconcile the same object twice.
   Keep Argo CD; Flux is an alternative requiring approval, not another reconciler.
   Prefer Azure-managed monitoring, backup, policy, security, and cost services
   from the README. Do not install Prometheus/Grafana/Alertmanager/Loki/Tempo,
   Velero, or OpenCost by default; document and approve unmet requirements first.
3. Pin chart/controller versions and image digests. Check target AKS, Kubernetes,
   Gateway API, and CRD compatibility. Sequence CRDs before custom resources and
   test upgrades in non-production.
4. Use restricted Argo CD AppProjects with explicit repository, namespace, cluster,
   and resource permissions. Keep enterprise administrative interfaces internal.
   Demo interfaces may use a documented public access exception with TLS,
   SSO/RBAC, and source restrictions where supported. Avoid unrestricted
   wildcard destinations.
5. Configure workload identity, scoped Key Vault access, and application
   SecretProviderClasses for the AKS Secrets Store CSI Driver; store references,
   not secret values. Prefer mounted secrets and test rotation/application reload.
   Justify ESO or Kubernetes Secret synchronization, accounting for namespace
   readers and backup exposure. Evaluate Application Gateway for Containers
   before adoption; configure Azure DNS/Key Vault certificate integration with
   supported controllers where needed and test issuance, renewal, and TLS reload.
6. Require probes, resource requests/limits, ownership labels, restricted pod
   security, and default-deny network policies with explicit required traffic.
   Include disruption/topology settings when workload availability requires them.
7. Map Azure Policy and Pod Security Admission controls; retain Kyverno for
   required signature verification or unsupported policies without duplicating
   enforcement. Defender scanning does not replace CI scanning/SBOM/signing or
   signature admission. Roll out new policies in audit mode before enforcement.
   Test allow/deny cases and signature trust identities. Exceptions must be
   scoped, justified, owned, and time-bounded.
8. Use available repository checks to lint/render Helm and Kustomize, validate
   target schemas/CRDs, and test policies. Do not invent a passing integration
   result when no cluster or tooling exists.
9. In an approved non-production environment, verify reconciliation, networking,
   TLS renewal, identity/secret rotation, telemetry, alerts, and restore behavior
   relevant to the change. Verify managed telemetry ingestion/query and Grafana
   data-source connectivity, RBAC, Action Group alert delivery, retention/costs,
   and Azure Backup coverage/restore restrictions for actual storage. Retain
   database-native backups. Report unavailable checks and unverified feature status.
10. Promote the same signed image digest using reviewed Git changes. Preserve
    production approvals and test pruning/deletion safety. Roll back through Git;
    document separate handling for irreversible data/schema changes.

## Completion evidence

Describe ownership, target environment, version changes, rendered/static checks,
integration evidence, rollback steps, and unresolved security or recovery risks.
Never apply production manifests or bypass GitOps merely to complete a review.

## AKS Labs: safe App of Apps workflow

Use the [App of Apps lab](https://github.com/Azure-Samples/aks-labs/blob/main/docs/platform-engineering/app-of-apps.md)
for modular composition and metadata-driven ApplicationSets, subject to the
Terraform/Azure/Argo CD contracts in `README.md`.

1. Establish a platform-owned root and separate child applications for approved
   platform components and team workloads. Protect roots, projects, generators,
   and cluster registration metadata; do not expose them as unrestricted
   developer-template inputs.
2. For justified multi-target delivery, use explicit environment/cluster
   selectors and allowlisted repositories, revisions, paths, and capabilities.
   Inspect generated applications before synchronization. Avoid dynamic
   AppProject or production destination selection by untrusted inputs.
3. Retrieve cluster authentication through approved runtime bootstrap, not Git.
   Cluster registration Secrets containing credentials remain sensitive; do not
   commit them even when some registration metadata is non-secret.
4. Check CRD/controller readiness before custom resources. Sync waves only order
   resources within their synchronization context; test child health handling or
   stage synchronization instead of assuming cross-application dependency safety.
5. Test drift/revert, bootstrap reruns, and parent/selector deletion in
   non-production. Explicitly review automated pruning, cascading finalizers,
   ApplicationSet resource preservation, and cluster deregistration behavior.
   Do not delete CRDs or adoption metadata as a generic ownership-conflict fix.
6. Keep managed-service capability flags from selecting duplicate self-hosted
   charts. Pin external lab-derived artifacts to reviewed versions/revisions.
   Kargo, Argo Rollouts/Events/Workflows, CAPZ, ASO, and kro are not baseline
   dependencies; require a concrete gap and approval before adding them.
