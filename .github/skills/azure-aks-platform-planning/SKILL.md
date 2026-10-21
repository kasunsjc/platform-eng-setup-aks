---
name: azure-aks-platform-planning
description: Plan or review an Azure-managed-first AKS developer platform using Terraform and open-source tools for gaps. Use for architecture, phased roadmaps, service selection, and production readiness.
---

# Azure AKS platform planning

1. Read `README.md` and `.github/copilot-instructions.md`. Distinguish existing
   implementation from proposed capabilities before recommending changes.
2. Confirm tenant/subscriptions, region, environments, team ownership, workload
   needs, budget, identity, DNS, data classification, and agreed SLO/RTO/RPO.
   List unresolved choices explicitly rather than inventing production values.
3. Map requirements to the selected stack. Keep Terraform responsible for Azure,
   Azure responsible for objects installed by its managed add-ons, Argo CD
   responsible for applications and remaining in-cluster components, and
   Backstage a later interface to approved workflows rather than an administrator.
   Retain Argo CD; Flux is an alternative, not a parallel reconciler.
   Prefer managed Prometheus, Managed Grafana, Azure Monitor alerts/Action Groups,
   Container Insights/Log Analytics, and Application Insights/OpenTelemetry.
   Prefer Azure Backup for AKS, Azure Policy, Defender for Containers, Azure
   Cost Management/AKS cost analysis, and Key Vault CSI-mounted secrets.
   Keep CI scanning/SBOM/signing and database-native backups; justify ESO,
   Kyverno signature verification/gap policies, OpenCost, or Velero separately.
   Evaluate Application Gateway for Containers and Azure DNS/Key Vault certificate
   integration, including required controllers and a documented ingress fallback.
4. Cover private networking and runner connectivity, state bootstrap/recovery,
   OIDC and Workload Identity, least privilege, secret rotation, admission policy,
   image provenance, observability, cost attribution, and tested backups.
5. Explain managed-service and licensing exceptions. Verify support and
   compatibility, region/SKU/GA status, private ingestion/query/Grafana paths,
   RBAC, telemetry costs/retention, and backup/restore coverage before adoption.
   Do not assume Key Vault provides complete certificate automation, Defender
   provides signature admission, or Azure Policy covers every Kyverno rule.
   Report outstanding verification; do not substitute
   OpenTofu for requested Terraform without approval.
6. Organize work into dependency-ordered phases with measurable acceptance gates,
   owners to be assigned, rollback/recovery expectations, risks, and open decisions.
   Prove one service's delivery path before expanding the platform.
7. Avoid overlapping controllers and unnecessary additions such as service mesh,
   Crossplane, or multi-region failover without a concrete requirement.
8. Return planning output to the requester. Update the repository plan only when
   asked to save it; keep `README.md` aligned and do not deploy infrastructure.

## Review checklist

- Every component has a purpose, ownership boundary, and operational cost.
- Production has a separate security and approval boundary.
- Bootstrap can reach private endpoints without permanently relaxing controls.
- Recovery includes persistent data, secret dependencies, and a restore exercise.
- Managed-service choices have coverage evidence; open-source exceptions have
  justification and approval rather than duplicate ownership.
- Proposed work is not presented as completed deployment or successful testing.
