{{- define "virtfoundry-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "virtfoundry-operator.fullname" -}}
{{- .Values.fullnamePrefix | default (include "virtfoundry-operator.name" .) -}}
{{- end -}}

{{- define "virtfoundry-operator.labels" -}}
app.kubernetes.io/name: {{ include "virtfoundry-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: virtfoundry
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "virtfoundry-operator.image" -}}
{{- if .Values.image.digest -}}
{{ .Values.image.repository }}@{{ .Values.image.digest }}
{{- else -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- end -}}
