{{/*
Expand the name of the chart.
*/}}
{{- define "cofide-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cofide-agent.fullname" -}}
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
{{- define "cofide-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cofide-agent.labels" -}}
helm.sh/chart: {{ include "cofide-agent.chart" . }}
{{ include "cofide-agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cofide-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cofide-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cofide-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cofide-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Full reference for an image, from a map of `registry`, `repository` and `tag`.
Call with a dict of `image` (the map) and `defaultTag` (used when `tag` is empty).

`registry` is optional: when empty the `repository` is used unqualified, so
images can be pulled from Docker Hub.
*/}}
{{- define "cofide-agent.imageRef" -}}
{{- $repository := .image.repository | required "A value for the image repository is required" -}}
{{- $tag := .image.tag | default .defaultTag -}}
{{- if .image.registry -}}
{{- printf "%s/%s:%s" .image.registry $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end }}

{{/*
Full image reference for the cofide-agent container. Defaults the tag to the chart appVersion.
*/}}
{{- define "cofide-agent.image" -}}
{{- include "cofide-agent.imageRef" (dict "image" .Values.image "defaultTag" .Chart.AppVersion) -}}
{{- end }}
