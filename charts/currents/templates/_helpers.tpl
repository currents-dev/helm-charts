{{/*
Create authentik server name and version as used by the chart label.
*/}}
{{- define "currents.server.fullname" -}}
{{- printf "%s-%s" (include "currents.fullname" .) .Values.server.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}