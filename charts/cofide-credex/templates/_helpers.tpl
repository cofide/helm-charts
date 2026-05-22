{{/*
Expand the name of the chart.
*/}}
{{- define "cofide-credex.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cofide-credex.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "cofide-credex.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cofide-credex.labels" -}}
helm.sh/chart: {{ include "cofide-credex.chart" . }}
{{ include "cofide-credex.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cofide-credex.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cofide-credex.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cofide-credex.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cofide-credex.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Determine the service port based on TLS configuration.
*/}}
{{- define "cofide-credex.servicePort" -}}
{{- if and .Values.credex.tls.enabled (eq (int .Values.service.port) 80) -}}
443
{{- else -}}
{{- .Values.service.port -}}
{{- end -}}
{{- end -}}

{{/*
Determine the target port based on TLS configuration.
*/}}
{{- define "cofide-credex.targetPort" -}}
{{- if and .Values.credex.tls.enabled (eq (int .Values.service.targetPort) 8080) -}}
8443
{{- else -}}
{{- .Values.service.targetPort -}}
{{- end -}}
{{- end -}}

{{/*
Determine the Liveness probe port based on TLS configuration.
*/}}
{{- define "cofide-credex.livenessProbePort" -}}
{{- if and .Values.credex.tls.enabled (eq (int .Values.livenessProbe.httpGet.port) 8080) -}}
8443
{{- else -}}
{{- .Values.livenessProbe.httpGet.port -}}
{{- end -}}
{{- end -}}

{{/*
Determine the Readiness probe port based on TLS configuration.
*/}}
{{- define "cofide-credex.readinessProbePort" -}}
{{- if and .Values.credex.tls.enabled (eq (int .Values.readinessProbe.httpGet.port) 8080) -}}
8443
{{- else -}}
{{- .Values.readinessProbe.httpGet.port -}}
{{- end -}}
{{- end -}}

{{/*
Determine the probe scheme based on TLS configuration.
*/}}
{{- define "cofide-credex.probeScheme" -}}
{{- if .Values.credex.tls.enabled -}}
HTTPS
{{- else -}}
HTTP
{{- end -}}
{{- end -}}

{{/*
Returns "true" when the local signer is in use, either as the active signer
or as an entry in extraJWKSSources. Empty otherwise.
*/}}
{{- define "cofide-credex.usesLocalSigning" -}}
{{- if or (eq .Values.credex.signing.method "local") (has "local" .Values.credex.signing.extraJWKSSources) -}}
true
{{- end -}}
{{- end -}}
