{{- define "virtforge.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "virtforge.namespace" -}}
{{- .Values.namespace }}
{{- end }}

{{- define "virtforge.fullname" -}}
{{- printf "%s-%s" .Values.fullnamePrefix .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "virtforge.labels" -}}
app.kubernetes.io/name: {{ include "virtforge.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "virtforge.imagePullSecrets" -}}
{{- with .Values.images.pullSecrets }}
imagePullSecrets:
  {{- range . }}
  - name: {{ . }}
  {{- end }}
{{- end }}
{{- end }}
