# Cofide Helm Charts

Helm chart mono-repo for Cofide's SPIFFE-based zero-trust infrastructure.

## Charts

| Chart | Description |
|---|---|
| [`cofide-agent`](charts/cofide-agent) | Deploys the Cofide Agent (SPIFFE workload identity agent) |
| [`cofide-connect`](charts/cofide-connect) | Deploys the Cofide Connect API server with an Envoy sidecar |
| [`cofide-connect-ui`](charts/cofide-connect-ui) | Deploys the Connect UI frontend with an Envoy sidecar |
| [`cofide-credex`](charts/cofide-credex/README.md) | Deploys Cofide Credex, an OAuth 2.0 AS and token exchange service |
| [`cofide-observer`](charts/cofide-observer) | Deploys the Cofide Observer (monitoring/observability) |
| [`cofide-trust-zone-operator`](charts/cofide-trust-zone-operator) | Kubernetes operator for managing `TrustZoneServer` CRs |
| [`cofide-tzaas-crds`](charts/cofide-tzaas-crds) | Installs the `TrustZoneServer` CRD — must be installed before `cofide-trust-zone-operator` |
| [`spiffe-enable`](charts/spiffe-enable/README.md) | Admission webhook that automates SPIFFE workload identity injection |

## Usage

Charts are published to the Cofide Helm repository. Add the repo and install:

```bash
helm repo add cofide https://cofide.github.io/helm-charts
helm repo update
helm install <release-name> cofide/<chart-name>
```
