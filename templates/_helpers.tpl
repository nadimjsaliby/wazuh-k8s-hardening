{{/*
Expand the name of the chart.
*/}}
{{- define "wazuh-k8s-hardening.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name (truncated to 63 chars for K8s).
*/}}
{{- define "wazuh-k8s-hardening.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label value.
*/}}
{{- define "wazuh-k8s-hardening.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "wazuh-k8s-hardening.labels" -}}
helm.sh/chart: {{ include "wazuh-k8s-hardening.chart" . }}
{{ include "wazuh-k8s-hardening.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: wazuh-k8s-hardening
app.kubernetes.io/component: agent
{{- if .Values.global }}
{{- if .Values.global.environment }}
environment: {{ .Values.global.environment }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels (subset of common labels used in matchLabels).
*/}}
{{- define "wazuh-k8s-hardening.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wazuh-k8s-hardening.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Admission webhook labels.
*/}}
{{- define "wazuh-k8s-hardening.webhookLabels" -}}
helm.sh/chart: {{ include "wazuh-k8s-hardening.chart" . }}
app.kubernetes.io/name: {{ include "wazuh-k8s-hardening.name" . }}-webhook
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: wazuh-k8s-hardening
app.kubernetes.io/component: admission-webhook
{{- end }}

{{/*
Admission webhook selector labels.
*/}}
{{- define "wazuh-k8s-hardening.webhookSelectorLabels" -}}
app.kubernetes.io/name: {{ include "wazuh-k8s-hardening.name" . }}-webhook
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "wazuh-k8s-hardening.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "wazuh-k8s-hardening.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Full image reference including tag.
*/}}
{{- define "wazuh-k8s-hardening.image" -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end }}

{{/*
Registration password secret name.
*/}}
{{- define "wazuh-k8s-hardening.secretName" -}}
{{- if .Values.manager.existingSecret }}
{{- .Values.manager.existingSecret }}
{{- else }}
{{- printf "%s-auth" (include "wazuh-k8s-hardening.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Webhook service name.
*/}}
{{- define "wazuh-k8s-hardening.webhookServiceName" -}}
{{- printf "%s-webhook" (include "wazuh-k8s-hardening.fullname" .) }}
{{- end }}

{{/*
Webhook certificate name.
*/}}
{{- define "wazuh-k8s-hardening.webhookCertName" -}}
{{- printf "%s-webhook-tls" (include "wazuh-k8s-hardening.fullname" .) }}
{{- end }}

{{/*
Metrics service name.
*/}}
{{- define "wazuh-k8s-hardening.metricsServiceName" -}}
{{- printf "%s-metrics" (include "wazuh-k8s-hardening.fullname" .) }}
{{- end }}

{{/*
Generate the list of enabled compliance policy paths for ossec.conf.
Returns a list of SCA policy file paths.
*/}}
{{- define "wazuh-k8s-hardening.scaPolicies" -}}
{{- if .Values.compliance.cisKubernetes.enabled }}
          <policy>/var/ossec/etc/shared/cis-kubernetes/cis_kubernetes_{{ lower .Values.compliance.cisKubernetes.profile }}.yml</policy>
{{- end }}
{{- if .Values.compliance.cisLinux.enabled }}
          <policy>/var/ossec/etc/shared/cis-linux/cis_linux_{{ lower .Values.compliance.cisLinux.profile }}.yml</policy>
{{- end }}
{{- if .Values.compliance.nist80053.enabled }}
          <policy>/var/ossec/etc/shared/nist-800-53/nist_800_53_k8s.yml</policy>
{{- end }}
{{- if .Values.compliance.pciDss.enabled }}
          <policy>/var/ossec/etc/shared/pci-dss/pci_dss_k8s.yml</policy>
{{- end }}
{{- if .Values.compliance.hipaa.enabled }}
          <policy>/var/ossec/etc/shared/hipaa/hipaa_k8s.yml</policy>
{{- end }}
{{- if .Values.compliance.soc2.enabled }}
          <policy>/var/ossec/etc/shared/soc2/soc2_k8s.yml</policy>
{{- end }}
{{- if .Values.compliance.runtimeThreatDetection.enabled }}
          <policy>/var/ossec/etc/shared/runtime/runtime_threat_detection.yml</policy>
{{- end }}
{{- end }}

{{/*
Return true if any compliance framework is enabled.
*/}}
{{- define "wazuh-k8s-hardening.anyComplianceEnabled" -}}
{{- or .Values.compliance.cisKubernetes.enabled .Values.compliance.cisLinux.enabled .Values.compliance.nist80053.enabled .Values.compliance.pciDss.enabled .Values.compliance.hipaa.enabled .Values.compliance.soc2.enabled .Values.compliance.runtimeThreatDetection.enabled -}}
{{- end }}
