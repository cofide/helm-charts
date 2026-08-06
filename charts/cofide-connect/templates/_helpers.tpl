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
Address (hostname, optionally with a port) for the TLS API endpoint (connect.<urlBase> by default).
*/}}
{{- define "cofide-connect.apiAddress" -}}
{{- if .Values.connect.apiAddress -}}
{{- .Values.connect.apiAddress -}}
{{- else -}}
connect.{{ .Values.connect.urlBase }}
{{- end -}}
{{- end }}

{{/*
TLS SNI for the TLS API endpoint. Defaults to apiAddress with any port stripped. Used only for
Envoy's filter_chain_match - there is no HTTP-layer use of this value.
*/}}
{{- define "cofide-connect.apiServerName" -}}
{{- if .Values.connect.apiServerName -}}
{{- .Values.connect.apiServerName -}}
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

{{/*
Full reference for an image, from a map of `registry`, `repository` and `tag`.
Call with a dict of `image` (the map) and `defaultTag` (used when `tag` is empty).

`registry` is optional: when empty the `repository` is used unqualified, so
images can be pulled from Docker Hub.
*/}}
{{- define "cofide-connect.imageRef" -}}
{{- $repository := .image.repository | required "A value for the image repository is required" -}}
{{- $tag := .image.tag | default .defaultTag -}}
{{- if .image.registry -}}
{{- printf "%s/%s:%s" .image.registry $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Full image reference for the cofide-connect container. Defaults the tag to the chart appVersion.
*/}}
{{- define "cofide-connect.image" -}}
{{- include "cofide-connect.imageRef" (dict "image" .Values.image "defaultTag" .Chart.AppVersion) -}}
{{- end }}

{{/*
Full image reference for the Envoy sidecar.

For backwards compatibility, `envoy.image` may still be set to a full image
reference string (with the pull policy in `envoy.imagePullPolicy`) instead of a
map of `registry`, `repository`, `pullPolicy` and `tag`.
*/}}
{{- define "cofide-connect.envoyImage" -}}
{{- if kindIs "string" .Values.envoy.image -}}
{{- .Values.envoy.image -}}
{{- else -}}
{{- include "cofide-connect.imageRef" (dict "image" .Values.envoy.image "defaultTag" "") -}}
{{- end -}}
{{- end }}

{{/*
Pull policy for the Envoy sidecar. Prefers `envoy.image.pullPolicy`, falling
back to the deprecated `envoy.imagePullPolicy`.
*/}}
{{- define "cofide-connect.envoyImagePullPolicy" -}}
{{- if kindIs "string" .Values.envoy.image -}}
{{- .Values.envoy.imagePullPolicy | default "IfNotPresent" -}}
{{- else -}}
{{- .Values.envoy.image.pullPolicy | default .Values.envoy.imagePullPolicy | default "IfNotPresent" -}}
{{- end -}}
{{- end }}
