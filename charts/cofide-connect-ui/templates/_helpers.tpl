{{/*
Expand the name of the chart.
*/}}
{{- define "cofide-connect-ui.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cofide-connect-ui.fullname" -}}
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
Full reference for an image, from a map of `registry`, `repository` and `tag`.
Call with a dict of `image` (the map) and `defaultTag` (used when `tag` is empty).

Prefer `registry` + `repository`, matching the other Cofide charts. For backwards
compatibility, a `repository` that already includes a registry host (its first
path segment looks like a hostname, e.g. `example.com/cofide/connect-ui` or
`localhost:5000/connect-ui`) is used as-is and `registry` is ignored.
*/}}
{{- define "cofide-connect-ui.imageRef" -}}
{{- $repository := .image.repository | required "A value for the image repository is required" -}}
{{- $tag := .image.tag | default .defaultTag -}}
{{- $host := splitList "/" $repository | first -}}
{{- if or (contains "." $host) (contains ":" $host) (eq $host "localhost") -}}
{{- printf "%s:%s" $repository $tag -}}
{{- else if .image.registry -}}
{{- printf "%s/%s:%s" .image.registry $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Full image reference for the UI container. Defaults the tag to the chart appVersion.
*/}}
{{- define "cofide-connect-ui.image" -}}
{{- include "cofide-connect-ui.imageRef" (dict "image" .Values.image "defaultTag" .Chart.AppVersion) -}}
{{- end }}

{{/*
Full image reference for the Envoy sidecar.
*/}}
{{- define "cofide-connect-ui.envoyImage" -}}
{{- include "cofide-connect-ui.imageRef" (dict "image" .Values.envoy.image "defaultTag" "") -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cofide-connect-ui.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cofide-connect-ui.labels" -}}
helm.sh/chart: {{ include "cofide-connect-ui.chart" . }}
{{ include "cofide-connect-ui.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cofide-connect-ui.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cofide-connect-ui.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
