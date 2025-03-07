{{/*
Expand the name of the chart.
*/}}
{{- define "currents.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "currents.fullname" -}}
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
{{- define "currents.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "currents.labels" -}}
helm.sh/chart: {{ include "currents.chart" .context | quote }}
{{ include "currents.selectorLabels" (dict "context" .context "component" .component) }}
{{- if .context.Chart.AppVersion }}
app.kubernetes.io/version: {{ .context.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .context.Release.Service }}
{{- with .context.Values.global.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "currents.selectorLabels" -}}
app.kubernetes.io/name: {{ include "currents.name" .context | quote }}
app.kubernetes.io/instance: {{ .context.Release.Name | quote }}
{{- if .component }}
app.kubernetes.io/component: {{ .component | quote }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "currents.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "currents.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "currents.image" -}}
{{- $registryName := default .imageRoot.registry ((.context.global).imageRegistry) -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $separator := ":" -}}
{{- $termination := .imageRoot.tag | toString -}}

{{- if not .imageRoot.tag }}
{{- $termination = default .context.Chart.AppVersion  ((.context.Values.global).imageTag) | toString -}}
{{- end -}}
{{- if .imageRoot.digest }}
{{- $separator = "@" -}}
{{- $termination = .imageRoot.digest | toString -}}
{{- end -}}
{{- if $registryName }}
{{- printf "%s/%s%s%s" $registryName $repositoryName $separator $termination -}}
{{- else -}}
{{- printf "%s%s%s"  $repositoryName $separator $termination -}}
{{- end -}}
{{- end -}}

