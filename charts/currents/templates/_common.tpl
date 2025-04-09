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
{{- $registryName := default .imageRoot.registry ((.context.Values.global).imageRegistry) -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $separator := ":" -}}
{{- $termination := .imageRoot.tag | toString -}}

{{- if not .imageRoot.tag }}
{{- $termination = default .context.Chart.AppVersion  ((.context.Values.currents).imageTag) | toString -}}
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

{{- define "currents.redis.host" -}}
{{ .Values.currents.redis.host }}
{{- end -}}

{{- define "currents.connectionConfigEnv" -}}
- name: REDIS_URI
  value: {{ printf "redis://%s:6379"  (tpl .Values.currents.redis.host .) }}
- name: REDIS_URI_SLAVE
  value: {{ printf "redis://%s:6379"  (tpl .Values.currents.redis.host .) }}
{{- if .Values.currents.mongoConnection.secretName }}
- name: MONGODB_URI
  valueFrom:
    secretKeyRef:
      name: {{ .Values.currents.mongoConnection.secretName }}
      key: {{ .Values.currents.mongoConnection.key }}
{{- end }}
- name: ELASTIC_URI
  value: {{ printf "%s://%s:%d" (.Values.currents.elastic.tls.enabled | ternary "https" "http") (tpl .Values.currents.elastic.host .) (.Values.currents.elastic.port | int) }}
{{- if .Values.currents.elastic.apiUser.secretName }}
- name: ELASTIC_API_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.currents.elastic.apiUser.secretName }}
      key: {{ .Values.currents.elastic.apiUser.idKey }}
- name: ELASTIC_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.currents.elastic.apiUser.secretName }}
      key: {{ .Values.currents.elastic.apiUser.secretKey }}
{{- end }}
- name: S3_BUCKET
  value: {{ .Values.currents.objectStorage.bucket }}
- name: FILE_STORAGE_BUCKET
  value: {{ .Values.currents.objectStorage.bucket }}
- name: FILE_STORAGE_ENDPOINT
  value: {{ .Values.currents.objectStorage.endpoint }}
{{- if .Values.currents.objectStorage.secretName }}
- name: FILE_STORAGE_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ .Values.currents.objectStorage.secretName }}
      key: {{ .Values.currents.objectStorage.secretIdKey }}
- name: FILE_STORAGE_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.currents.objectStorage.secretName }}
      key: {{ .Values.currents.objectStorage.secretAccessKey }}
{{- end }}
{{- if .Values.currents.objectStorage.pathStyle }}
- name: FILE_STORAGE_FORCE_PATH_STYLE
  value: "true"
{{- end }}
{{- if .Values.currents.objectStorage.internalEndpoint }}
- name: FILE_STORAGE_INTERNAL_ENDPOINT
  value: {{ .Values.currents.objectStorage.internalEndpoint }}
{{- end }}
{{- if .Values.currents.logger.apiEndpoint }}
- name: CORALOGIX_API_ENDPOINT
  value: {{ .Values.currents.logger.apiEndpoint }}
{{- end }}
{{- if .Values.currents.logger.apiSecretName }}
- name: CORALOGIX_API_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.currents.logger.apiSecretName }}
      key: {{ .Values.currents.logger.apiSecretKey }}
{{- end }}
{{- end -}}

{{- define "currents.URLConfigEnv" -}}
- name: GITLAB_REDIRECT_URL
  value: {{ printf "%s/integrations/gitlab/callback" (include "currents.url" (dict "context" . "input" .Values.currents.domains.recordApiHost)) }}
- name: APP_BASE_URL
  value: {{ include "currents.url" (dict "context" . "input"  .Values.currents.domains.appHost) }}
- name: DASHBOARD_URL
  value: {{ include "currents.url" (dict "context" . "input" .Values.currents.domains.appHost) }}
- name: CURRENTS_RECORD_API_URL
  value: {{ include "currents.url" (dict "context" . "input" .Values.currents.domains.recordApiHost) }}
{{- end -}}

{{- define "currents.elasticDataStreamsEnv" -}}
{{- if .Values.currents.elastic.datastreams.tests }}
- name: ELASTIC_DATASTREAM_TESTS
  value: {{ .Values.currents.elastic.datastreams.tests }}
{{- end }}
{{- if .Values.currents.elastic.datastreams.runs }}
- name: ELASTIC_DATASTREAM_RUNS
  value: {{ .Values.currents.elastic.datastreams.runs }}
{{- end }}
{{- if .Values.currents.elastic.datastreams.instances }}
- name: ELASTIC_DATASTREAM_INSTANCES
  value: {{ .Values.currents.elastic.datastreams.instances }}
{{- end }}
{{- end -}}

{{- define "currents.emailSMTPEnv" -}}
- name: EMAIL_TRANSPORTER
  value: smtp
{{- if .Values.currents.email.smtp.host }}
- name: SMTP_HOST
  value: {{ .Values.currents.email.smtp.host }}
{{- end }}
{{- if .Values.currents.email.smtp.port }}
- name: SMTP_PORT
  value: {{ .Values.currents.email.smtp.port | toString | quote }}
{{- end }}
{{- if .Values.currents.email.smtp.tls }}
- name: SMTP_SECURE
  value: "true"
{{- end }}
{{- if .Values.currents.email.smtp.secretName }}
- name: SMTP_USER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.currents.email.smtp.secretName }}
      key: {{ .Values.currents.email.smtp.secretUserKey }}
{{- end }}
{{- if .Values.currents.email.smtp.secretName }}
- name: SMTP_PASS
  valueFrom:
    secretKeyRef:
      name: {{ .Values.currents.email.smtp.secretName }}
      key: {{ .Values.currents.email.smtp.secretPasswordKey }}
{{- end }}
- name: AUTOMATED_REPORTS_CURRENTS_DASHBOARD_HOSTNAME
  value: {{ include "currents.url" (dict "context" . "input" .Values.currents.domains.appHost) }}
- name: AUTOMATED_REPORTS_EMAIL_FROM
  value: {{ tpl .Values.currents.email.smtp.from . }}
{{- end -}}