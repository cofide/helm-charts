{{/*
Expand the name of the chart.
*/}}
{{- define "cofide-connect.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cofide-connect.fullname" -}}
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
{{- define "cofide-connect.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cofide-connect.labels" -}}
helm.sh/chart: {{ include "cofide-connect.chart" . }}
{{ include "cofide-connect.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cofide-connect.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cofide-connect.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cofide-connect.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cofide-connect.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Address (hostname, optionally with a port) for the JWT API endpoint (connect.<urlBase> by default).
*/}}
{{- define "cofide-connect.apiAddress" -}}
{{- if .Values.connect.apiAddress -}}
{{- .Values.connect.apiAddress -}}
{{- else -}}
connect.{{ .Values.connect.urlBase }}
{{- end -}}
{{- end }}

{{/*
TLS SNI for the JWT API endpoint. Defaults to apiAddress with any port stripped. Used only for
Envoy's filter_chain_match - there is no HTTP-layer use of this value.
*/}}
{{- define "cofide-connect.apiServername" -}}
{{- if .Values.connect.apiServername -}}
{{- .Values.connect.apiServername -}}
{{- else -}}
{{- regexReplaceAll ":[0-9]+$" (include "cofide-connect.apiAddress" .) "" -}}
{{- end -}}
{{- end }}

{{/*
TLS SNI for the SPIFFE mTLS endpoint (connect-agent.<urlBase> by default). Used only for Envoy's
filter_chain_match - there is no HTTP-layer use of this value.
*/}}
{{- define "cofide-connect.mtlsServerName" -}}
{{- if .Values.connect.mtlsServerName -}}
{{- .Values.connect.mtlsServerName -}}
{{- else -}}
connect-agent.{{ .Values.connect.urlBase }}
{{- end -}}
{{- end }}

{{/*
TLS SNI for the XDS/ADS endpoint (xds.<urlBase> by default). Used only for Envoy's
filter_chain_match - there is no HTTP-layer use of this value.
*/}}
{{- define "cofide-connect.xdsServerName" -}}
{{- if .Values.connect.xdsServerName -}}
{{- .Values.connect.xdsServerName -}}
{{- else -}}
xds.{{ .Values.connect.urlBase }}
{{- end -}}
{{- end }}

{{- define "cofide-connect.envoy.auth.audiences" -}}
{{- if gt (len .Values.envoy.auth.audiences) 0 }}
{{- toYaml .Values.envoy.auth.audiences }}
{{- else -}}
- https://{{ include "cofide-connect.apiAddress" . }}
{{- range .Values.connect.apiExtraEndpoints }}
- https://{{ .address }}
{{- end }}
{{- end }}
{{- end }}
