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

{{/*
Linux IFNAMSIZ is 16 including NUL → host bridge names must be ≤15 chars.
"virtfoundry-pub0" is 16 and Multus fails with "numerical result out of range".
*/}}
{{- define "virtfoundry.validateBridgeNames" -}}
{{- $pub := .Values.platform.networking.public.bridge.name | default "" -}}
{{- $iso := .Values.platform.networking.isolated.bridge.name | default "" -}}
{{- if and .Values.platform.networking.public.enabled (gt (len $pub) 15) -}}
{{- fail (printf "platform.networking.public.bridge.name %q exceeds Linux IFNAMSIZ (max 15 chars); use e.g. vf-pub0" $pub) -}}
{{- end -}}
{{- if and .Values.platform.networking.isolated.enabled (gt (len $iso) 15) -}}
{{- fail (printf "platform.networking.isolated.bridge.name %q exceeds Linux IFNAMSIZ (max 15 chars)" $iso) -}}
{{- end -}}
{{- if eq $pub "virtfoundry-pub0" -}}
{{- fail "platform.networking.public.bridge.name \"virtfoundry-pub0\" is invalid (16 chars); use vf-pub0" -}}
{{- end -}}
{{- end }}

{{- define "virtfoundry.imagePullSecrets" -}}
{{- with .Values.images.pullSecrets }}
imagePullSecrets:
  {{- range . }}
  - name: {{ . }}
  {{- end }}
{{- end }}
{{- end }}
