{{- define "virtfoundry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "virtfoundry.namespace" -}}
{{- .Values.namespace }}
{{- end }}

{{- define "virtfoundry.fullname" -}}
{{- printf "%s-%s" .Values.fullnamePrefix .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "virtfoundry.labels" -}}
app.kubernetes.io/name: {{ include "virtfoundry.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "virtfoundry.imagePullSecrets" -}}
{{- with .Values.images.pullSecrets }}
imagePullSecrets:
  {{- range . }}
  - name: {{ . }}
  {{- end }}
{{- end }}
{{- end }}
