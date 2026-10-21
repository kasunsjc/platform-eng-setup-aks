# Azure AKS platform engineering plan

Build an internal developer platform on Azure Kubernetes Service (AKS), provision
Azure infrastructure with Terraform, and prefer Azure-managed services where they
meet requirements. Retain open-source tools for gaps rather than duplicating
managed capabilities. Start with a small, usable paved road before adding a
developer portal.

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
log retention, and backup retention with stakeholders. Verify each selected
service's regional availability, SKU, feature status (GA or preview), Terraform
support, private connectivity, quotas, and AKS/version compatibility before
implementation. These checks remain outstanding; this plan does not claim
current feature availability or support parity.

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

Terraform -> Azure network, DNS, identities, state, ACR, Key Vault, AKS
          -> Azure monitoring, backup, policy, and managed add-on configuration
Separate bootstrap -> Argo CD -> applications and remaining in-cluster components

AKS workloads -> Workload Identity -> scoped Azure services
             -> managed Prometheus -> Azure Managed Grafana
             -> Container Insights -> Log Analytics
             -> Azure Monitor OpenTelemetry -> Application Insights
             -> Azure Backup for AKS + application-native database backups
Azure Monitor alerts -> Action Groups -> responders
```

### Tool selection

| Capability | Preferred choice | Responsibility and exceptions |
| --- | --- | --- |
| Azure infrastructure | Terraform, AzureRM provider | Versioned modules and isolated environment state |
| Kubernetes runtime | AKS with Azure CNI Overlay and supported Cilium networking | Private API, network-policy enforcement, system/user node pools |
| Delivery | Argo CD, Helm, Kustomize | Pull-based reconciliation and environment overlays |
| Image builds | BuildKit, OCI images stored in ACR | Reproducible builds and immutable digest promotion |
| Supply-chain checks | Microsoft Defender for Containers; Trivy, Syft, Cosign in CI | Defender complements, not replaces, CI scanning, SBOMs, signing, and admission verification |
| Application ingress | Evaluate Application Gateway for Containers | Gate adoption on required Gateway API routes, private frontend/networking, regional support, and cost; retain Traefik if requirements are unmet |
| DNS and certificates | Azure DNS, Key Vault certificates, appropriate Kubernetes controllers | Scope DNS automation; use cert-manager/ExternalDNS where required and supported; Key Vault alone does not issue and renew every application certificate or configure Gateway TLS |
| Secrets | Azure Key Vault with AKS Secrets Store CSI Driver | Prefer mounted secrets and Workload Identity; use ESO only for justified synchronization needs |
| Policy | Azure Policy for AKS and Pod Security Admission | Use Kyverno for required signature verification or unsupported policies; avoid overlapping enforcement |
| Prometheus metrics | Azure Monitor managed service for Prometheus | Managed collection/storage via Azure Monitor workspace; no default self-hosted Prometheus |
| Dashboards | Azure Managed Grafana | Entra access and scoped data-source permissions; no default in-cluster Grafana |
| Alerting | Azure Monitor alerts and Action Groups | Prometheus/log/metric alert rules and tested routing; no default self-hosted Alertmanager |
| Container logs | Container Insights and Log Analytics | Bounded collection/retention and access controls instead of Loki |
| Application traces | Application Insights with Azure Monitor OpenTelemetry | Instrument applications and test supported SDK/export paths instead of deploying Tempo |
| Backup | Azure Backup for AKS and application-native database backups | Validate storage coverage and restore restrictions; consider Velero only for documented unmet requirements |
| Cost visibility | Azure Cost Management and AKS cost analysis | Verify SKU/access and allocation coverage; use OpenCost only for unmet requirements |
| Developer experience, later | Backstage | Catalog, ownership, docs, and approved templates; no assumed direct Azure replacement |

Pin compatible, supported releases during implementation, including Helm charts,
providers, modules, Kubernetes versions, Gateway API CRDs, and controller versions.
Do not assume that every optional enterprise feature is available in a tool's
open-source edition. Verify Gateway API route support and AKS networking
compatibility in development before adopting them. Argo CD remains the GitOps
controller; Azure's Flux-based GitOps is an alternative requiring an explicit
decision, not an additional reconciler for the same resources.

### Managed-service adoption gates

- **Observability:** provision Azure Monitor workspace, Log Analytics workspace,
  Application Insights, Managed Grafana, data collection rules/associations,
  alert rules, and Action Groups through Terraform. Verify the selected agents,
  sampling, scrape coverage, PromQL/dashboard compatibility, ingestion limits,
  retention, and per-environment cost budgets. Do not assume managed Prometheus
  provides identical retention/configuration options to self-hosted Prometheus.
- **Private access:** validate ingestion, query, Grafana data sources, user access,
  and DNS separately. Evaluate Azure Monitor Private Link Scope and each service's
  own private endpoint/managed private endpoint capabilities and tiers. A private
  dashboard endpoint does not by itself make all telemetry paths private.
- **Backup:** verify Azure Backup for AKS coverage for actual CSI drivers, volume
  types, region, cluster versions, vault tier, retention, and target restore
  topology. Record unsupported resources and cross-region/subscription restrictions.
  A snapshot alone is not an independent disaster-recovery backup; use supported
  vaulted protection where required and test application-consistent restores.
- **Security:** Azure Policy is not a drop-in replacement for every Kyverno rule,
  and Defender scanning is not image-signature admission enforcement. Map controls
  to one enforcement owner and retain explicit trusted signing identities.
- **Edge and TLS:** evaluate Application Gateway for Containers before selection;
  do not assume private frontend or route-feature support. If it cannot meet the
  requirements, document the Traefik fallback. Verify certificate issuance,
  Key Vault import/access, controller integration, renewal, and TLS reload.

Do not deploy parallel self-hosted observability stacks or blanket fallback
controllers. Record the requirement, operational cost, and approval for exceptions.

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
- Publish only intended application routes through the selected gateway.
  Keep Argo CD and Backstage internal initially and select Managed Grafana
  networking that meets private-access requirements. Authenticate with Entra
  ID/OIDC and apply team-scoped authorization and data-source RBAC.
- Use Entra groups for humans and least-privilege RBAC. Disable local AKS accounts.
  Enable AKS OIDC issuer and Workload Identity; scope each workload identity to
  its service account and required Azure resources.
- GitHub Actions authenticates to Azure through federated OIDC credentials,
  restricted to the repository and approved environment/ref. Do not use stored
  client secrets, storage account keys, or broad subscription Owner grants.
- Prefer Key Vault CSI-mounted secrets. Test rotation and application reload;
  environment variables do not automatically refresh. CSI secret synchronization
  and optional ESO create Kubernetes Secrets: restrict readers, protect backups,
  and document why synchronization is needed. Keep secret values out of Git, Helm
  values, Terraform inputs/state wherever possible, plans, and logs.

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
    monitoring/              # Managed telemetry, collection, alerting, Grafana
    backup/                  # Azure Backup vault, policies, supported protection
    policy/                  # Azure Policy assignments and Defender configuration
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
6. Terraform owns Azure resources, including monitoring, backup, policy, managed
   add-on enablement, extensions, identities, and associated Azure configuration.
   Azure manages objects installed by its enabled add-ons/extensions; exclude
   those objects from Argo CD ownership. Argo CD owns application manifests and
   remaining in-cluster components, including application SecretProviderClasses
   and any approved fallback controllers. Document the bootstrap handoff and
   resource inventory: no object may have competing reconciliation owners.

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
where supported, autoscaling, managed identities, Azure Policy for AKS, Defender
for Containers, the Key Vault CSI add-on, and an upgrade strategy. Review their
permissions and cost before enablement. Define namespace quotas, requests/limits, default-deny network
policies with explicit DNS/dependency allowances, disruption budgets, and
topology spread constraints.

**Exit gate:** unauthorized users cannot administer the cluster; a sample pod can
pull from ACR and use its scoped workload identity; prohibited cross-namespace
traffic is blocked; upgrades and node drains preserve the agreed availability.

### 3. GitOps, edge, and security

Bootstrap Argo CD and select the ingress controller only after the managed-edge
evaluation. Install required CRDs/controllers in dependency order without taking
ownership of Azure-managed objects. Configure Azure DNS and Key Vault certificate
integration with cert-manager/ExternalDNS only where required. Scope DNS writes
to the intended zone. Prefer CSI-mounted secrets; justify ESO separately.
Test certificate validation and renewal, including any DNS challenge path.
Map Azure Policy and Pod Security Admission controls, retaining Kyverno for
signature verification or gaps. Start new policies in audit mode, fix violations,
then enforce with narrowly scoped, expiring exceptions.

**Exit gate:** one sample service deploys from Git with valid TLS, restricted
network access, rotated secrets, and verified images. Drift is detected, a
bad image/pod is rejected, and a Git revert restores the previous release.

### 4. Reliability, observability, and cost

Provision managed Prometheus, Managed Grafana, Container Insights/Log Analytics,
and Application Insights with Azure Monitor OpenTelemetry. Configure collection,
sampling, supported retention controls, Entra/data-source permissions, Azure
Monitor alerts, and Action Groups. Keep sensitive request data out of telemetry.
Enable Azure Cost Management reporting and supported AKS cost analysis; add
OpenCost only if a documented allocation requirement remains unmet.

Configure Azure Backup for AKS with scoped identities, vault/policy retention,
supported storage protection, and recovery runbooks. Verify coverage and restore
restrictions for actual storage classes and target clusters before relying on it.
Use database-native backups where consistency requires them; approve Velero only
for a documented gap rather than deploying two overlapping backup owners.

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
| Policies | Azure Policy compliance/enforcement and Pod Security Admission allow/deny cases; Kyverno CLI tests for retained signature rules or gaps |
| Managed services | Region/SKU/GA status, provider support, managed add-on ownership, private ingestion/query/Grafana data-source paths, collection rules, and RBAC |
| Integration | Private DNS/API reachability, network-policy allow/deny cases, CSI rotation/application reload, TLS renewal, GitOps drift/rollback, and trace/log/metric correlation |
| Operations | Node drain/upgrade rehearsal, Action Group alert delivery, actual volume backup coverage and isolated restore to agreed RTO/RPO, and cost/retention review |

## Cost and operational trade-offs

Start with the smallest viable non-production footprint and add components only
when their exit gates can be supported. Budget for node pools, production
redundancy, networking/egress, private endpoints, ACR tiers, DNS, storage, backups,
and telemetry ingestion/retention. Include Managed Grafana capacity/tier, monitored
metric series, log ingestion, trace sampling, alerts, Defender, and backup
protected instances/storage in estimates. Azure-managed services reduce operating
work but are not necessarily open source or cheaper; review lock-in, export
options, retention limits, and service dependencies. Open-source exceptions still
need maintenance and Azure capacity. Defer service mesh, Crossplane, multi-cluster orchestration,
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
- [Azure Monitor managed Prometheus](https://learn.microsoft.com/azure/azure-monitor/metrics/prometheus-metrics-overview)
- [Azure Managed Grafana](https://learn.microsoft.com/azure/managed-grafana/overview)
- [Container Insights](https://learn.microsoft.com/azure/azure-monitor/containers/container-insights-overview)
- [Azure Monitor OpenTelemetry](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-overview)
- [Azure Monitor Action Groups](https://learn.microsoft.com/azure/azure-monitor/alerts/action-groups)
- [AKS backup support matrix](https://learn.microsoft.com/azure/backup/azure-kubernetes-service-cluster-backup-support-matrix)
- [AKS Key Vault CSI driver](https://learn.microsoft.com/azure/aks/csi-secrets-store-driver)
- [Azure Policy for Kubernetes](https://learn.microsoft.com/azure/governance/policy/concepts/policy-for-kubernetes)
- [Defender for Containers](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-containers-introduction)
- [AKS cost analysis](https://learn.microsoft.com/azure/aks/cost-analysis)
- [Application Gateway for Containers](https://learn.microsoft.com/azure/application-gateway/for-containers/overview)
- [Terraform Azure Blob backend](https://developer.hashicorp.com/terraform/language/backend/azurerm)
- [Argo CD documentation](https://argo-cd.readthedocs.io/en/stable/)
- [GitHub Copilot repository instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions)
- [GitHub Copilot agent skills](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
