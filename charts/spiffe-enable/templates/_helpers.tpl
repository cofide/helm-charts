{{/*
Expand the name of the chart.
*/}}
{{- define "spiffe-webhook.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "spiffe-webhook.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "spiffe-webhook.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "spiffe-webhook.labels" -}}
helm.sh/chart: {{ include "spiffe-webhook.chart" . }}
{{ include "spiffe-webhook.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: webhook
{{- end -}}

{{/*
Selector labels.
These are used to identify the pods for the Service and Deployment.
The 'app' label is derived from webhook.appName to match original manifests.
*/}}
{{- define "spiffe-webhook.selectorLabels" -}}
app: {{ .Values.webhook.appName | default (include "spiffe-webhook.name" .) }}
app.kubernetes.io/name: {{ include "spiffe-webhook.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "spiffe-webhook.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "spiffe-webhook.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for cert-manager resources.
*/}}
{{- define "cert-manager.apiVersion" -}}
{{- print "cert-manager.io/v1" -}}
{{- end -}}
