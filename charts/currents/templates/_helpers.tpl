{{/*
Create director name and version as used by the chart label.
*/}}
{{- define "currents.director.fullname" -}}
{{- printf "%s-%s" (include "currents.fullname" .) .Values.director.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

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

{{/*
Create writer name and version as used by the chart label.
*/}}
{{- define "currents.writer.fullname" -}}
{{- printf "%s-%s" (include "currents.fullname" .) .Values.writer.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create change-streams name and version as used by the chart label.
*/}}
{{- define "currents.changestreams.fullname" -}}
{{- printf "%s-%s" (include "currents.fullname" .) .Values.changestreams.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}