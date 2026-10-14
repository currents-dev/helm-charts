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
{{- $redis := .Values.currents.redis }}
{{- if $redis.connection.secretName }}
- name: REDIS_URI
  valueFrom:
    secretKeyRef:
      name: {{ $redis.connection.secretName }}
      key: {{ $redis.connection.key }}
- name: REDIS_URI_SLAVE
  valueFrom:
    secretKeyRef:
      name: {{ $redis.connection.secretName }}
      key: {{ $redis.connection.readerKey | default $redis.connection.key }}
{{- else }}
{{- $scheme := ternary "rediss" "redis" $redis.tls.enabled }}
{{- $reader := default $redis.host $redis.readerHost }}
- name: REDIS_URI
  value: {{ printf "%s://%s:%v" $scheme (tpl $redis.host .) $redis.port | quote }}
- name: REDIS_URI_SLAVE
  value: {{ printf "%s://%s:%v" $scheme (tpl $reader .) $redis.port | quote }}
{{- end }}
{{- if .Values.currents.mongoConnection.secretName }}
- name: MONGODB_URI
  valueFrom:
    secretKeyRef:
      name: {{ .Values.currents.mongoConnection.secretName }}
      key: {{ .Values.currents.mongoConnection.key }}
{{- end }}
- name: CLICKHOUSE_URL
  value: {{ printf "%s://%s:%d" (.Values.currents.clickhouse.tls.enabled | ternary "https" "http") (tpl .Values.currents.clickhouse.host .) (.Values.currents.clickhouse.port | int) }}
{{- if and .Values.currents.clickhouse.user.secretName .Values.currents.clickhouse.user.secretPasswordKey }}
- name: CLICKHOUSE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.currents.clickhouse.user.secretName }}
      key: {{ .Values.currents.clickhouse.user.secretPasswordKey }}
  {{- if and .Values.currents.clickhouse.user.username }}
- name: CLICKHOUSE_USERNAME
  value: {{ .Values.currents.clickhouse.user.username }}
  {{- end }}
{{- end }}
{{- if and .Values.currents.clickhouse.user.secretName .Values.currents.clickhouse.user.secretAccessTokenKey }}
- name: CLICKHOUSE_ACCESS_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ .Values.currents.clickhouse.user.secretName }}
      key: {{ .Values.currents.clickhouse.user.secretAccessTokenKey }}
{{- end }}
- name: S3_BUCKET
  value: {{ .Values.currents.objectStorage.bucket }}
- name: FILE_STORAGE_BUCKET
  value: {{ .Values.currents.objectStorage.bucket }}
- name: FILE_STORAGE_ENDPOINT
  value: {{ .Values.currents.objectStorage.endpoint }}
{{- if .Values.currents.objectStorage.region }}
- name: FILE_STORAGE_REGION
  value: {{ .Values.currents.objectStorage.region }}
{{- end }}
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

{{/*
ClickHouse restore mode.

Suppresses change-stream-driven ClickHouse sync while an organization's
ClickHouse data is loaded from an external export (scripts/org-import).
*/}}
{{- define "currents.clickhouseRestoreModeEnv" -}}
{{- if (.Values.maintenance).clickhouseRestoreMode }}
- name: CURRENTS_CLICKHOUSE_RESTORE_MODE
  value: "true"
{{- end }}
{{- end -}}

{{- define "currents.URLConfigEnv" -}}
- name: GITLAB_REDIRECT_URL
  value: {{ printf "%s/integrations/gitlab/callback" (include "currents.url" (dict "context" . "input" .Values.currents.domains.recordApiHost)) }}
- name: APP_BASE_URL
  value: {{ include "currents.url" (dict "context" . "input"  .Values.currents.domains.appHost) }}
- name: BETTER_AUTH_URL
  value: {{ include "currents.url" (dict "context" . "input" .Values.currents.domains.appHost) }}
- name: DASHBOARD_URL
  value: {{ include "currents.url" (dict "context" . "input" .Values.currents.domains.appHost) }}
- name: CURRENTS_RECORD_API_URL
  value: {{ include "currents.url" (dict "context" . "input" .Values.currents.domains.recordApiHost) }}
{{- end -}}

{{- define "currents.emailEnv" -}}
{{- $email := .Values.currents.email -}}
{{- $transporter := $email.transporter | default "smtp" -}}
{{- if not (has $transporter (list "smtp" "ses")) -}}
{{- fail (printf "currents.email.transporter must be either \"smtp\" or \"ses\", got %q" $transporter) -}}
{{- end -}}
- name: EMAIL_TRANSPORTER
  value: {{ $transporter | quote }}
{{- if eq $transporter "ses" }}
{{- /* Credentials are resolved by the AWS SDK from the pod itself (IRSA on EKS),
       so there is no secret to wire up here — only the region. */}}
- name: SES_REGION
  value: {{ required "currents.email.ses.region is required when currents.email.transporter is \"ses\"" $email.ses.region | quote }}
{{- else }}
{{- if $email.smtp.host }}
- name: SMTP_HOST
  value: {{ $email.smtp.host }}
{{- end }}
{{- if $email.smtp.port }}
- name: SMTP_PORT
  value: {{ $email.smtp.port | toString | quote }}
{{- end }}
{{- if $email.smtp.tls }}
- name: SMTP_SECURE
  value: "true"
{{- end }}
{{- if $email.smtp.secretName }}
- name: SMTP_USER
  valueFrom:
    secretKeyRef:
      name: {{ $email.smtp.secretName }}
      key: {{ $email.smtp.secretUserKey }}
{{- end }}
{{- if $email.smtp.secretName }}
- name: SMTP_PASS
  valueFrom:
    secretKeyRef:
      name: {{ $email.smtp.secretName }}
      key: {{ $email.smtp.secretPasswordKey }}
{{- end }}
{{- end }}
- name: AUTOMATED_REPORTS_CURRENTS_DASHBOARD_HOSTNAME
  value: {{ include "currents.url" (dict "context" . "input" .Values.currents.domains.appHost) }}
- name: AUTOMATED_REPORTS_EMAIL_FROM
  value: {{ tpl (default $email.smtp.from $email.from) . }}
{{- if .Values.currents.email.inviteFrom }}
- name: INVITE_EMAIL_FROM
  value: {{ tpl .Values.currents.email.inviteFrom . }}
{{- end }}
{{- if .Values.currents.email.inviteBcc }}
- name: INVITE_EMAIL_BCC
  value: {{ .Values.currents.email.inviteBcc }}
{{- end }}
{{- if .Values.currents.email.reportsBcc }}
- name: AUTOMATED_REPORTS_EMAIL_BCC
  value: {{ .Values.currents.email.reportsBcc }}
{{- end }}
{{- if .Values.currents.email.inviteExpirationDays }}
- name: INVITE_EXPIRATION_DAYS
  value: {{ .Values.currents.email.inviteExpirationDays | quote }}
{{- end }}
{{- if .Values.currents.email.linksBaseUrl }}
- name: EMAIL_LINKS_BASE_URL
  value: {{ .Values.currents.email.linksBaseUrl }}
{{- end }}
{{- end -}}

{{- define "currents.samlSSOEnv" -}}
{{- if .Values.currents.sso.saml.enabled }}
- name: SSO_SAML_IDP_METADATA_FILE
  value: {{ printf "/etc/currents/sso/%s" .Values.currents.sso.saml.metadataKey | quote }}
- name: SSO_SAML_ISSUER
  value: {{ required "currents.sso.saml.issuer is required when currents.sso.saml.enabled is true" .Values.currents.sso.saml.issuer | quote }}
{{- if .Values.currents.sso.saml.providerId }}
- name: SSO_SAML_PROVIDER_ID
  value: {{ .Values.currents.sso.saml.providerId | quote }}
{{- end }}
{{- if .Values.currents.sso.saml.defaultRole }}
- name: SSO_SAML_DEFAULT_ROLE
  value: {{ .Values.currents.sso.saml.defaultRole | quote }}
{{- end }}
{{- if .Values.currents.sso.saml.allowedDomains }}
- name: SSO_ALLOWED_DOMAINS
  value: {{ .Values.currents.sso.saml.allowedDomains | quote }}
{{- end }}
{{- if .Values.currents.sso.saml.authnRequestsSigned }}
- name: SSO_SAML_AUTHN_REQUESTS_SIGNED
  value: "true"
- name: SSO_SAML_SP_KEY_FILE
  value: {{ printf "/etc/currents/sso/%s" .Values.currents.sso.saml.spKeyKey | quote }}
{{- end }}
{{- /* toString, so a quoted "false" stays off: any non-empty string is true to `if`. */}}
{{- if eq (toString .Values.currents.sso.saml.allowIdpInitiated) "true" }}
- name: SSO_SAML_ALLOW_IDP_INITIATED
  value: "true"
{{- end }}
{{- end }}
{{- end -}}

{{/*
Whether the OAuth provider can run on appHost. The API refuses to start with it on
over http unless the host is loopback or in OAUTH_HTTP_ALLOWED_HOSTS, and Better
Auth advertises an https issuer for any http host but localhost and *.localhost,
so OAuth over http works only on those names.
*/}}
{{- define "currents.oauthSupported" -}}
{{- $hostname := regexReplaceAll ":[0-9]+$" (lower .Values.currents.domains.appHost) "" -}}
{{- if or .Values.currents.domains.https (eq $hostname "localhost") (hasSuffix ".localhost" $hostname) -}}
true
{{- end -}}
{{- end -}}

{{- define "currents.mcpOAuthEnv" -}}
- name: MCP_ENABLED
  value: {{ .Values.currents.mcp.enabled | toString | quote }}
{{- if .Values.currents.mcp.origins }}
- name: MCP_ORIGINS
  value: {{ .Values.currents.mcp.origins | quote }}
{{- end }}
{{- $oauth := .Values.currents.oauth }}
{{- if and $oauth.enabled (include "currents.oauthSupported" .) }}
- name: OAUTH_PROVIDER_ENABLED
  value: "true"
{{- if not .Values.currents.domains.https }}
{{- /* Over http, appHost is localhost or *.localhost. The API checks each access
       token against its own signing keys, fetched from appHost by default, and a
       pod resolves neither name to the API. */}}
- name: OAUTH_JWKS_URL
  value: {{ printf "http://localhost:%v/api/auth/jwks" .Values.server.service.port | quote }}
{{- $hostname := regexReplaceAll ":[0-9]+$" (lower .Values.currents.domains.appHost) "" }}
{{- if hasSuffix ".localhost" $hostname }}
- name: OAUTH_HTTP_ALLOWED_HOSTS
  value: {{ $hostname | quote }}
{{- end }}
{{- end }}
{{- if $oauth.dynamicClientRegistration }}
- name: OAUTH_DYNAMIC_CLIENT_REGISTRATION_ENABLED
  value: "true"
{{- end }}
{{- if not $oauth.clientIdMetadataDocuments }}
- name: OAUTH_CIMD_ENABLED
  value: "false"
{{- end }}
{{- end }}
{{- end -}}

{{/*
The app-content bucket, rendered as the PERMANENT_STORAGE_* the services read.
Unset fields take the artifact bucket's values, so one endpoint and one set of
credentials serve both buckets by default. The internal endpoint and region come
along only with the endpoint: with its own endpoint, the artifact storage's
internal endpoint would send the pods to the wrong storage.
*/}}
{{- define "currents.appContentStorageEnv" -}}
{{- $acs := .Values.currents.appContentStorage }}
{{- $os := .Values.currents.objectStorage }}
{{- if $acs.bucket }}
{{- $location := ternary $acs $os (not (empty $acs.endpoint)) }}
- name: PERMANENT_STORAGE_BUCKET
  value: {{ $acs.bucket | quote }}
- name: PERMANENT_STORAGE_ENDPOINT
  value: {{ required "currents.appContentStorage.endpoint or currents.objectStorage.endpoint is required when currents.appContentStorage.bucket is set" $location.endpoint | quote }}
{{- with (default $location.internalEndpoint $acs.internalEndpoint) }}
- name: PERMANENT_STORAGE_INTERNAL_ENDPOINT
  value: {{ . | quote }}
{{- end }}
{{- with (default $location.region $acs.region) }}
- name: PERMANENT_STORAGE_REGION
  value: {{ . | quote }}
{{- end }}
{{- with (default $os.secretName $acs.secretName) }}
- name: PERMANENT_STORAGE_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: {{ default $os.secretIdKey $acs.secretIdKey }}
- name: PERMANENT_STORAGE_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ . }}
      key: {{ default $os.secretAccessKey $acs.secretAccessKey }}
{{- end }}
{{- if (kindIs "bool" $acs.pathStyle | ternary $acs.pathStyle $os.pathStyle) }}
- name: PERMANENT_STORAGE_FORCE_PATH_STYLE
  value: "true"
{{- end }}
{{- end }}
{{- end -}}
