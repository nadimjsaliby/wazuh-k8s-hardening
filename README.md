<!--
  Wazuh K8s Hardening
  Copyright (C) 2026 Nadim Saliby <contact@nadimjsaliby.com>
  Licensed under AGPL-3.0 — see LICENSE file
-->

# Wazuh K8s Hardening

Enterprise-grade Helm chart that deploys Wazuh agents as a DaemonSet on Kubernetes with **multi-framework compliance policies**, **admission webhook enforcement**, **auto-remediation**, **runtime threat detection**, and **full observability**.

## What Makes This Different

| Capability | This Chart | Typical Wazuh Helm Charts |
|---|---|---|
| Compliance Frameworks | CIS + NIST 800-53 + PCI-DSS + HIPAA + SOC2 | CIS only |
| Admission Webhook | Blocks non-compliant workloads pre-deploy | None |
| Auto-Remediation | CronJob fixes discovered findings | Detect only |
| Runtime Threat Detection | MITRE ATT&CK-mapped behavioral checks | Basic rootcheck |
| Observability | Prometheus metrics + Grafana dashboards + PrometheusRules | None |
| Compliance Reporting | Scheduled JSON/HTML/CSV with S3 upload | Manual |
| Alert Routing | Slack, PagerDuty, email integrations | Basic syslog |
| Self-Hardening | NetworkPolicy, PDB, seccomp, cert-manager mTLS | Open network |
| Manager HA | Multi-manager failover configuration | Single manager |
| Values Schema | JSON Schema validation for all inputs | None |

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        Kubernetes Cluster                            │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Admission Webhook                         │    │
│  │  Validates: privileged, hostNetwork, hostPID, image policy  │    │
│  │  Blocks non-compliant workloads BEFORE deployment           │    │
│  └──────────────────────────┬──────────────────────────────────┘    │
│                              │                                       │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐      ┌──────────────────┐  │
│  │  Node 1  │ │  Node 2  │ │  Node N  │      │   Prometheus     │  │
│  │┌────────┐│ │┌────────┐│ │┌────────┐│      │   ┌──────────┐  │  │
│  ││ Wazuh  ││ ││ Wazuh  ││ ││ Wazuh  ││◄────►│   │ Grafana  │  │  │
│  ││ Agent  ││ ││ Agent  ││ ││ Agent  ││      │   │Dashboard │  │  │
│  ││        ││ ││        ││ ││        ││      │   └──────────┘  │  │
│  ││+Metrics││ ││+Metrics││ ││+Metrics││      └──────────────────┘  │
│  │└───┬────┘│ │└───┬────┘│ │└───┬────┘│                            │
│  └────┼─────┘ └────┼─────┘ └────┼─────┘                            │
│       │            │            │                                    │
│  ┌────┼────────────┼────────────┼──────────────────────────────┐    │
│  │    └────────────┼────────────┘                              │    │
│  │                 ▼                                           │    │
│  │  ┌──────────────────────────┐  ┌──────────────────────┐   │    │
│  │  │     Wazuh Manager        │  │  Auto-Remediation    │   │    │
│  │  │  ┌────────────────────┐  │  │  CronJob Engine      │   │    │
│  │  │  │ SCA Engine         │  │  │  ┌────────────────┐  │   │    │
│  │  │  │ • CIS K8s/Linux    │  │  │  │ Fix Findings   │  │   │    │
│  │  │  │ • NIST 800-53      │  │  │  │ SSH Hardening  │  │   │    │
│  │  │  │ • PCI-DSS v4.0     │  │  │  │ Kernel Params  │  │   │    │
│  │  │  │ • HIPAA            │  │  │  │ File Perms     │  │   │    │
│  │  │  │ • SOC2 Type II     │  │  │  │ Audit Rules    │  │   │    │
│  │  │  │ • Runtime Threats   │  │  │  └────────────────┘  │   │    │
│  │  │  └────────────────────┘  │  └──────────────────────┘   │    │
│  │  └──────────────────────────┘                              │    │
│  │                 │                                           │    │
│  │  ┌──────────────▼──────────────┐                           │    │
│  │  │  Compliance Report CronJob  │  ──► S3 / Email / Slack  │    │
│  │  │  JSON • HTML • CSV          │                           │    │
│  │  └─────────────────────────────┘                           │    │
│  └────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Kubernetes >= 1.25
- Helm >= 3.x
- A running Wazuh Manager accessible from the cluster
- (Optional) cert-manager for webhook and agent mTLS
- (Optional) Prometheus Operator for ServiceMonitor/PrometheusRule
- (Optional) Grafana with sidecar for dashboard auto-discovery

## Quick Start

```bash
# Minimal deployment with CIS + NIST policies
helm install wazuh-hardening ./wazuh-k8s-hardening \
  --namespace wazuh-system --create-namespace \
  --set manager.host=wazuh-manager.wazuh.svc.cluster.local \
  --set manager.registrationPassword=YOUR_PASSWORD
```

## Production Deployment

```bash
# Create namespace and secret
kubectl create namespace wazuh-system
kubectl create secret generic wazuh-auth \
  --namespace wazuh-system \
  --from-literal=registration-password=YOUR_PASSWORD

# Deploy with full enterprise features
helm install wazuh-hardening ./wazuh-k8s-hardening \
  --namespace wazuh-system \
  -f production-values.yaml
```

Example `production-values.yaml`:

```yaml
global:
  clusterName: "prod-us-east-1"
  environment: "production"
  organization: "Acme Corp"
  complianceContact: "security@acme.com"

manager:
  host: "wazuh-manager.wazuh.svc.cluster.local"
  existingSecret: "wazuh-auth"
  failover:
    enabled: true
    hosts:
      - host: "wazuh-manager-2.wazuh.svc.cluster.local"
  tls:
    enabled: true
    issuerRef:
      name: "letsencrypt-prod"
      kind: "ClusterIssuer"

compliance:
  cisKubernetes:
    profile: "L2"
  cisLinux:
    profile: "L2"
  nist80053:
    enabled: true
  pciDss:
    enabled: true
  hipaa:
    enabled: true
  soc2:
    enabled: true

admissionWebhook:
  enabled: true
  replicas: 3
  failurePolicy: "Fail"
  certManager:
    enabled: true
    issuerRef:
      name: "internal-ca"
      kind: "ClusterIssuer"

autoRemediation:
  enabled: true
  dryRun: false
  schedule: "0 */4 * * *"
  notifications:
    enabled: true
    slackWebhookUrl: "https://hooks.slack.com/services/..."
    slackChannel: "#security-ops"

complianceReport:
  enabled: true
  schedule: "0 2 * * 0"
  formats:
    json: true
    html: true
    csv: true
  s3Upload:
    enabled: true
    bucket: "acme-compliance-reports"
    region: "us-east-1"
    existingSecret: "aws-credentials"

metrics:
  enabled: true
  serviceMonitor:
    enabled: true
  prometheusRule:
    enabled: true

grafana:
  enabled: true

alertRouting:
  integrations:
    slack:
      enabled: true
      webhookUrl: "https://hooks.slack.com/services/..."
      minLevel: 10
    pagerduty:
      enabled: true
      apiKey: "YOUR_PD_KEY"
      minLevel: 12
```

## Compliance Frameworks

| Framework | Checks | Focus Areas |
|---|---|---|
| **CIS Kubernetes v1.8.0** | L1: 19, L2: 12 | Control plane, worker nodes, pod security, network policies |
| **CIS Linux v2.0.0** | L1: 22, L2: 14 | Filesystem, network, logging, SSH, access control |
| **NIST 800-53 Rev5** | 24 | AC, AU, CM, IA, SC, SI control families |
| **PCI-DSS v4.0** | 20 | Network segmentation, encryption, access, logging, FIM |
| **HIPAA §164.312** | 16 | Access control, audit, integrity, authentication, transmission |
| **SOC2 Type II** | 18 | CC6-CC8, A1 trust services criteria |
| **Runtime Threats** | 22 | Cryptomining, container escape, reverse shells, persistence (MITRE ATT&CK) |

## Admission Webhook Policies

When enabled, the webhook validates workloads **before** deployment:

| Policy | Default | Description |
|---|---|---|
| `blockPrivileged` | `true` | Reject privileged containers |
| `blockHostNetwork` | `true` | Reject hostNetwork pods |
| `blockHostPID` | `true` | Reject hostPID pods |
| `blockHostIPC` | `true` | Reject hostIPC pods |
| `requireRunAsNonRoot` | `true` | Require non-root containers |
| `blockPrivilegeEscalation` | `true` | Block allowPrivilegeEscalation |
| `blockLatestTag` | `true` | Reject :latest image tags |
| `requireImageDigest` | `false` | Require image digest references |
| `requiredLabels` | `[name, version]` | Enforce required labels |

## Auto-Remediation

The remediation engine runs as a CronJob and can fix:

- **File permissions** — /etc/passwd, /etc/shadow, K8s manifests
- **Kernel parameters** — sysctl hardening (redirects, source routing, SYN cookies)
- **SSH hardening** — PermitRootLogin, MaxAuthTries, idle timeouts
- **Filesystem modules** — Disable cramfs, squashfs, udf
- **Auditd rules** — Audit watch rules for critical files

Always start with `dryRun: true` to review what changes would be made.

## Observability

### Prometheus Metrics

| Metric | Type | Description |
|---|---|---|
| `wazuh_agent_up` | gauge | Agent running status per node |
| `wazuh_sca_checks_passed` | gauge | SCA checks passed |
| `wazuh_sca_checks_failed` | gauge | SCA checks failed |
| `wazuh_fim_events_total` | counter | File integrity events |
| `wazuh_vulnerabilities_detected` | gauge | Vulnerabilities found |
| `wazuh_alerts_total` | counter | Total alerts generated |

### PrometheusRule Alerts

- `WazuhAgentDown` — Agent offline > 5 min (critical)
- `WazuhHighSCAFailureRate` — >30% checks failing (warning)
- `WazuhCriticalSCAFailures` — >50% checks failing (critical)
- `WazuhVulnerabilitiesDetected` — >50 vulns (warning)
- `WazuhFIMSpikeDetected` — Unusual file change rate (warning)
- `WazuhAlertStorm` — >50 alerts/sec (critical)

## Testing

```bash
# Run Helm tests
helm test wazuh-hardening -n wazuh-system

# Lint the chart
helm lint .

# Template with debug
helm template test . --debug \
  --set manager.host=test \
  --set manager.registrationPassword=test
```

## Uninstall

```bash
helm uninstall wazuh-hardening --namespace wazuh-system
```

## Author

**Nadim Saliby** — [contact@nadimjsaliby.com](mailto:contact@nadimjsaliby.com)

## License

**AGPL-3.0** — GNU Affero General Public License v3.0

This means:
- You **can** use, modify, and distribute this chart freely
- You **must** open-source any modifications you make
- You **must** keep the same AGPL-3.0 license on derivative works
- You **cannot** use this in proprietary/closed-source products
- If you deploy a modified version as a network service, you **must** release your source code

See [LICENSE](LICENSE) for the full text.
