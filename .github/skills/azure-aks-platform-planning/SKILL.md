---
name: azure-aks-platform-planning
description: Plan or review an Azure AKS internal developer platform using Terraform and open-source tools. Use for architecture, phased roadmaps, tool selection, and production-readiness decisions.
---

# Azure AKS platform planning

1. Read `README.md` and `.github/copilot-instructions.md`. Distinguish existing
   implementation from proposed capabilities before recommending changes.
2. Confirm tenant/subscriptions, region, environments, team ownership, workload
   needs, budget, identity, DNS, data classification, and agreed SLO/RTO/RPO.
   List unresolved choices explicitly rather than inventing production values.
3. Map requirements to the selected stack. Keep Terraform responsible for Azure,
   Argo CD responsible for Kubernetes delivery, and Backstage a later interface
   to approved workflows rather than an infrastructure administrator.
4. Cover private networking and runner connectivity, state bootstrap/recovery,
   OIDC and Workload Identity, least privilege, secret rotation, admission policy,
   image provenance, observability, cost attribution, and tested backups.
5. Explain managed-service and licensing exceptions. Verify support and
   compatibility before recommending specific versions; do not substitute
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
- Proposed work is not presented as completed deployment or successful testing.
