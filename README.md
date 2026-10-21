# Azure AKS platform engineering plan

Build an internal developer platform on Azure Kubernetes Service (AKS), provision
Azure infrastructure with Terraform, and use open-source platform tools wherever
practical. Start with a small, usable paved road before adding a developer portal.

**Status:** design only. This repository does not yet contain deployable Terraform,
Kubernetes manifests, pipelines, or an installed platform. All directories and
validation commands below are proposed unless explicitly marked as existing.

## Outcomes and scope

- Developers can onboard a service, build an image, and deploy through a reviewed
  GitOps change without receiving cluster-admin permissions.
- Platform operators own reusable infrastructure, security policies, reliability,
  and a documented recovery process.
- Separate development, staging, and production boundaries; promote the same
  immutable application image rather than rebuilding for each environment.
- Begin with one region. Add multi-region disaster recovery only when agreed
  recovery objectives justify the additional complexity and cost.

Azure, AKS, Entra ID, Key Vault, Azure Container Registry (ACR), and GitHub hosting
are managed services, not open-source software. Terraform is explicitly requested;
current HashiCorp Terraform releases are source-available under the Business
Source License, not OSI-approved open source. Confirm license suitability before
implementation; if strict open-source licensing is mandatory, seek approval to
substitute OpenTofu rather than silently replacing Terraform. Review licenses
and support status for every selected tool and pinned release.

## Decisions required before provisioning

Confirm Azure tenant/subscriptions, region and availability-zone support, naming
and tags, domain and DNS ownership, identity groups, expected workload sizes,
data residency, budget, and production availability requirements. Agree numerical
service SLOs, recovery time objectives (RTO), recovery point objectives (RPO),
log retention, and backup retention with stakeholders.

Use separate subscriptions for non-production and production where possible.
For an initial pilot, development and staging may share a non-production cluster
with namespace isolation; production uses a separate cluster, state, identities,
and approval boundary. Namespaces alone are not a strong hostile-tenant boundary.

## Target architecture

```text
Developer -> pull request -> GitHub Actions -> build/scan -> ACR
                         -> reviewed image-digest update in GitOps
                                                    |
                                                    v
Backstage (later) -> approved repository workflow -> Argo CD -> AKS workloads

Terraform -> Azure network, private DNS, identities, state, ACR, Key Vault, AKS
          -> one-time Argo CD bootstrap -> GitOps owns platform/workload releases

AKS workloads -> Workload Identity -> scoped Azure services
             -> OpenTelemetry -> Prometheus / Grafana / Loki / Tempo
             -> application-native backups + Velero -> Azure Blob Storage
```

### Tool selection

| Capability | Initial choice | Responsibility |
| --- | --- | --- |
| Azure infrastructure | Terraform, AzureRM provider | Versioned modules and isolated environment state |
| Kubernetes runtime | AKS with Azure CNI Overlay and supported Cilium networking | Private API, network-policy enforcement, system/user node pools |
| Delivery | Argo CD, Helm, Kustomize | Pull-based reconciliation and environment overlays |
| Image builds | BuildKit, OCI images stored in ACR | Reproducible builds and immutable digest promotion |
| Supply-chain checks | Trivy, Syft, Cosign | Vulnerability checks, SBOMs, signing and verification |
| Traffic and TLS | Traefik with Gateway API, cert-manager, ExternalDNS | Routing, certificates, and scoped DNS automation |
| Secrets | External Secrets Operator (ESO), Azure Key Vault | Workload Identity authentication and controlled secret synchronization |
| Policy | Kyverno and Kubernetes Pod Security Admission | Trusted images, restricted pods, required metadata and limits |
| Metrics and dashboards | Prometheus, Alertmanager, Grafana | Platform SLOs, actionable alerts, developer dashboards |
| Logs and traces | Loki, Tempo, OpenTelemetry Collector | Correlated telemetry with retention and access controls |
| Backup | Velero and application-native database backups | Restore-tested Kubernetes resources and supported volume data |
| Cost visibility | OpenCost | Namespace/team allocation and capacity tuning |
| Developer experience, later | Backstage | Catalog, ownership, docs, and approved service templates |

Pin compatible, supported releases during implementation, including Helm charts,
providers, modules, Kubernetes versions, Gateway API CRDs, and controller versions.
Do not assume that every optional enterprise feature is available in a tool's
open-source edition. Verify Gateway API route support and AKS networking
compatibility in development before adopting them.

### Network and identity boundaries

- Use a VNet with deliberate address planning, separate node and private-endpoint
  subnets as required, private DNS links, and controlled outbound connectivity.
  Document required destinations before restricting egress; consider Azure
  Firewall when the threat model warrants it.
- Keep the AKS API private. Run deployment jobs on ephemeral, isolated runners
  with VNet connectivity, private DNS resolution, and access to required Azure
  endpoints. Never expose the API publicly merely to make hosted CI work.
- Prefer private endpoints for ACR, Key Vault, Terraform state, and backup storage
  where supported by the chosen service tiers. Include tier costs and DNS tests.
- Publish only intended application routes through a dedicated load balancer and
  gateway. Keep Argo CD, Grafana, and Backstage internal initially; authenticate
  with Entra ID/OIDC and apply team-scoped authorization.
- Use Entra groups for humans and least-privilege RBAC. Disable local AKS accounts.
  Enable AKS OIDC issuer and Workload Identity; scope each workload identity to
  its service account and required Azure resources.
- GitHub Actions authenticates to Azure through federated OIDC credentials,
  restricted to the repository and approved environment/ref. Do not use stored
  client secrets, storage account keys, or broad subscription Owner grants.
- ESO synchronization creates Kubernetes Secrets: restrict readers, protect
  backups, and test refresh/rotation. Keep secret values out of Git, Helm values,
  Terraform inputs/state wherever possible, plans, and logs.

## Terraform and GitOps ownership

### Proposed repository layout

```text
infra/
  bootstrap/                 # State storage and initial federation
  modules/
    network/
    identity/
    acr/
    key-vault/
    aks/
  environments/
    dev/
    staging/
    prod/
platform/
  bootstrap/                 # Argo CD installation and initial root application
  applications/              # Platform component definitions
  environments/
    dev/
    staging/
    prod/
templates/                   # Later: service skeletons and Backstage templates
```

These paths do not exist yet. Add them only as implementation phases begin.
Keep application source in service repositories and decide whether their GitOps
configuration stays here or moves to a dedicated deployment repository.

### State and bootstrap

1. An authorized operator establishes narrowly scoped bootstrap access and a
   network-connected execution path. Create Azure Blob remote-state storage with
   Entra data-plane RBAC, encryption, versioning, soft delete, and locking via
   blob leases. Establish private connectivity before disabling public access.
2. Bootstrap starts with local state only if necessary. Treat it as sensitive,
   migrate it to the remote backend, verify access and recovery, then securely
   remove local copies. Never commit state or bootstrap credentials.
3. Isolate bootstrap and each environment in separate state keys and access
   boundaries. Use separate production storage/access controls where appropriate;
   Terraform workspaces alone do not provide authorization isolation.
4. Pin Terraform and provider constraints; commit provider lock files for each
   root module. Exclude `.terraform/`, state, saved plans, secrets, and
   credential-bearing variable files when those artifacts are introduced.
5. Provision Azure infrastructure, then install Argo CD through a separate,
   explicit bootstrap step with private cluster access. Do not combine an
   unknown/new cluster endpoint and Kubernetes provider setup in one initial apply.
6. Hand chart releases and Kubernetes objects to Argo CD. Document the ownership
   boundary: Terraform and Argo CD must never reconcile the same object.

### Delivery and change control

- Infrastructure pull requests run formatting, initialization without backend
  access where appropriate, validation, TFLint, and Trivy configuration scanning.
  Trusted plans run with scoped read/plan permissions and remote-state access.
- Run no privileged plans or deployments on untrusted fork code. Use minimal
  GitHub token permissions and pin third-party Actions to reviewed commit SHAs.
- Serialize operations by environment/state. Require protected production
  environments and human approval. Apply only a reviewed, short-lived saved plan
  from the same commit; re-plan if state or code changes. Saved plans may contain
  secrets: use restricted, short-retention artifacts and never publish them.
- Service CI runs tests, builds an image, creates an SBOM, scans and signs the
  image, and opens a GitOps pull request with its immutable digest. Verify
  signatures at admission against explicit trusted identities.
- Argo CD uses restricted AppProjects, repository access, and destination scopes.
  Enable production pruning/automatic synchronization only after testing rollback,
  ordering, and deletion protections. Do not deploy production using CI `kubectl`.
- Roll back applications by reverting the GitOps digest/configuration change.
  Treat database migrations separately with backward-compatible rollout plans.
  Infrastructure rollback requires a reviewed corrective plan, not blind state edits.

## Phased rollout and acceptance gates

### 1. Foundation and bootstrap

Agree the decisions above; establish subscriptions, tags, identities, budgets,
remote state, network, private DNS, ACR, Key Vault, and runner connectivity.

**Exit gate:** a trusted runner authenticates without static credentials, resolves
private endpoints, accesses isolated state, and produces a reviewed Terraform
plan. Budget alerts, ownership, and state recovery responsibilities are assigned.

### 2. AKS baseline

Create private AKS with separate system and user node pools, zone distribution
where supported, autoscaling, managed identities, policy enforcement, and an
upgrade strategy. Define namespace quotas, requests/limits, default-deny network
policies with explicit DNS/dependency allowances, disruption budgets, and
topology spread constraints.

**Exit gate:** unauthorized users cannot administer the cluster; a sample pod can
pull from ACR and use its scoped workload identity; prohibited cross-namespace
traffic is blocked; upgrades and node drains preserve the agreed availability.

### 3. GitOps, edge, and security

Bootstrap Argo CD, install Gateway API CRDs/controllers in dependency order,
then cert-manager, ExternalDNS, ESO, and Kyverno. Scope DNS writes to the intended
zone. Test certificate validation and renewal, including the DNS challenge path
if used for internal services. Start new admission policies in audit mode, fix
violations, then enforce with narrowly scoped, expiring exceptions.

**Exit gate:** one sample service deploys from Git with valid TLS, restricted
network access, rotated secrets, and verified images. Drift is detected, a
bad image/pod is rejected, and a Git revert restores the previous release.

### 4. Reliability, observability, and cost

Install metrics, logs, traces, and OpenCost with team ownership labels and bounded
retention. Keep sensitive request data out of telemetry. Configure alert routing,
runbooks, backup storage permissions, and encrypted backups. Verify the Velero
Azure integration and CSI snapshot/data-mover support for the actual storage
classes; a volume snapshot alone is not an independent disaster-recovery backup.
Use database-native backups where consistency requires them.

**Exit gate:** a synthetic failure reaches an accountable responder; dashboards
show service health and team costs; a restore into a separate namespace/cluster
meets the agreed RTO/RPO, including required persistent data and secret recovery.

### 5. Developer paved road

First prove a repository template and reviewed workflow for a sample service:
ownership, Dockerfile, build/test checks, probes, resource settings, network
policies, dashboards, and environment configuration. Then add Backstage catalog,
SSO, documentation, and templates that invoke those same approved workflows.
Do not give the portal unrestricted Terraform or cluster-admin access.

**Exit gate:** a developer onboards a service, deploys to development, promotes
the same signed digest through staging and production approval, finds telemetry,
and rolls back without requiring platform-admin credentials.

### 6. Production readiness and ongoing operations

Exercise incident response, restore procedures, identity revocation, certificate
and secret rotation, policy exceptions, vulnerability remediation, and AKS/chart
upgrades in non-production. Assign component owners and upgrade windows.

**Exit gate:** production launch has explicit SLO/RTO/RPO sign-off, security and
cost review, tested runbooks, restore evidence, and a documented support model.

## Validation during implementation

No lint, build, or test tooling is currently configured in this repository.
Introduce checks alongside the implementation they validate; do not report a
successful cloud deployment based on static checks alone.

| Area | Planned checks |
| --- | --- |
| Terraform | `terraform fmt -check -recursive`, per-root `terraform init -backend=false` and `terraform validate`; TFLint; Trivy config scan; trusted environment-specific plans |
| Helm/Kustomize | `helm lint`, `helm template`, `kustomize build`, and rendered schema validation against target Kubernetes/CRD versions |
| Policies | Kyverno CLI tests for accepted/rejected workloads and signature trust rules |
| Integration | Private DNS/API reachability, least-privilege RBAC, network-policy allow/deny cases, secret rotation, TLS renewal, GitOps drift/rollback |
| Operations | Node drain/upgrade rehearsal, alert delivery, isolated restore, and cost/retention review |

## Cost and operational trade-offs

Start with the smallest viable non-production footprint and add components only
when their exit gates can be supported. Budget for node pools, production
redundancy, networking/egress, private endpoints, ACR tiers, DNS, storage, backups,
and telemetry ingestion/retention. Open-source software still needs maintenance
and Azure capacity. Defer service mesh, Crossplane, multi-cluster orchestration,
and multi-region failover until a concrete requirement warrants them; retain
Terraform as the single Azure infrastructure owner.

## GitHub Copilot guidance

Repository-wide guidance lives in
[`.github/copilot-instructions.md`](.github/copilot-instructions.md).
Task-specific skills use GitHub's `.github/skills/<name>/SKILL.md` convention:

- [Platform planning](.github/skills/azure-aks-platform-planning/SKILL.md)
- [Terraform delivery](.github/skills/azure-terraform-delivery/SKILL.md)
- [AKS GitOps delivery](.github/skills/aks-gitops-delivery/SKILL.md)

These files guide Copilot; they do not enforce branch protections, Azure RBAC,
policy admission, or GitHub environment approvals. Configure those controls
separately during implementation.

## References

- [AKS baseline architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/baseline-aks)
- [AKS Workload Identity](https://learn.microsoft.com/azure/aks/workload-identity-overview)
- [Terraform Azure Blob backend](https://developer.hashicorp.com/terraform/language/backend/azurerm)
- [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/)
- [GitHub Copilot repository instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions)
- [GitHub Copilot agent skills](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
