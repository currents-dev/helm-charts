{{/*
Create server name and version as used by the chart label.
*/}}
{{- define "currents.server.fullname" -}}
{{- printf "%s-%s" (include "currents.fullname" .) .Values.server.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create scheduler name and version as used by the chart label.
*/}}
{{- define "currents.scheduler.fullname" -}}
{{- printf "%s-%s" (include "currents.fullname" .) .Values.scheduler.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}