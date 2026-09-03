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

{{/*
Resolve StorageClass: explicit value, else Longhorn if present, else cluster default, else local-path.
lookup is empty during `helm template` / CI — falls back to local-path.
*/}}
{{- define "virtfoundry.storageDefaultClass" -}}
{{- $explicit := .Values.platform.storage.defaultClass | default "" | toString | trim -}}
{{- if and $explicit (ne $explicit "auto") -}}
{{- $explicit -}}
{{- else -}}
{{- $longhorn := lookup "storage.k8s.io/v1" "StorageClass" "" "longhorn" -}}
{{- if $longhorn -}}
longhorn
{{- else -}}
{{- $found := "" -}}
{{- $scs := lookup "storage.k8s.io/v1" "StorageClass" "" "" -}}
{{- if and $scs $scs.items -}}
{{- range $scs.items -}}
{{- $ann := index .metadata.annotations "storageclass.kubernetes.io/is-default-class" | default "" -}}
{{- if eq $ann "true" -}}
{{- $found = .metadata.name -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if $found -}}
{{- $found -}}
{{- else -}}
local-path
{{- end -}}
{{- end -}}
{{- end -}}
{{- end }}

{{- define "virtfoundry.storageSnapshotClass" -}}
{{- $explicit := .Values.platform.storage.snapshotClass | default "" | toString | trim -}}
{{- if $explicit -}}
{{- $explicit -}}
{{- else -}}
{{- $sc := include "virtfoundry.storageDefaultClass" . -}}
{{- if eq $sc "longhorn" -}}
longhorn
{{- else -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
When public.autoFromCluster is true, prefer a /24 from the first Node InternalIP.
Falls back to values.yaml during helm template (no API server). Never sets uplink.
*/}}
{{- define "virtfoundry.publicCIDR" -}}
{{- $fromNode := "" -}}
{{- if .Values.platform.networking.public.autoFromCluster -}}
{{- $ip := include "virtfoundry.nodeInternalIPv4" . -}}
{{- if $ip -}}
{{- $parts := splitList "." $ip -}}
{{- if eq (len $parts) 4 -}}
{{- $fromNode = printf "%s.%s.%s.0/24" (index $parts 0) (index $parts 1) (index $parts 2) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if $fromNode -}}
{{- $fromNode -}}
{{- else -}}
{{- .Values.platform.networking.public.cidr -}}
{{- end -}}
{{- end }}

{{- define "virtfoundry.publicGateway" -}}
{{- $fromNode := "" -}}
{{- if .Values.platform.networking.public.autoFromCluster -}}
{{- $ip := include "virtfoundry.nodeInternalIPv4" . -}}
{{- if $ip -}}
{{- $parts := splitList "." $ip -}}
{{- if eq (len $parts) 4 -}}
{{- $fromNode = printf "%s.%s.%s.1" (index $parts 0) (index $parts 1) (index $parts 2) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if $fromNode -}}
{{- $fromNode -}}
{{- else -}}
{{- .Values.platform.networking.public.gateway -}}
{{- end -}}
{{- end }}

{{- define "virtfoundry.publicPoolStart" -}}
{{- $fromNode := "" -}}
{{- if .Values.platform.networking.public.autoFromCluster -}}
{{- $ip := include "virtfoundry.nodeInternalIPv4" . -}}
{{- if $ip -}}
{{- $parts := splitList "." $ip -}}
{{- if eq (len $parts) 4 -}}
{{- $fromNode = printf "%s.%s.%s.20" (index $parts 0) (index $parts 1) (index $parts 2) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if $fromNode -}}
{{- $fromNode -}}
{{- else -}}
{{- .Values.platform.networking.public.ipPool.start -}}
{{- end -}}
{{- end }}

{{- define "virtfoundry.publicPoolEnd" -}}
{{- $fromNode := "" -}}
{{- if .Values.platform.networking.public.autoFromCluster -}}
{{- $ip := include "virtfoundry.nodeInternalIPv4" . -}}
{{- if $ip -}}
{{- $parts := splitList "." $ip -}}
{{- if eq (len $parts) 4 -}}
{{- $fromNode = printf "%s.%s.%s.80" (index $parts 0) (index $parts 1) (index $parts 2) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if $fromNode -}}
{{- $fromNode -}}
{{- else -}}
{{- .Values.platform.networking.public.ipPool.end -}}
{{- end -}}
{{- end }}

{{- define "virtfoundry.publicDNS" -}}
{{- $ip := include "virtfoundry.nodeInternalIPv4" . -}}
{{- if and .Values.platform.networking.public.autoFromCluster $ip -}}
[{{ include "virtfoundry.publicGateway" . | quote }}]
{{- else -}}
{{- .Values.platform.networking.public.dns | toJson -}}
{{- end -}}
{{- end }}

{{- define "virtfoundry.nodeInternalIPv4" -}}
{{- $ip := "" -}}
{{- $nodes := lookup "v1" "Node" "" "" -}}
{{- if and $nodes $nodes.items -}}
{{- range $nodes.items -}}
{{- if not $ip -}}
{{- range .status.addresses -}}
{{- if and (not $ip) (eq .type "InternalIP") (contains "." .address) -}}
{{- $ip = .address -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $ip -}}
{{- end }}

{{- define "virtfoundry.imagePullSecrets" -}}
{{- with .Values.images.pullSecrets }}
imagePullSecrets:
  {{- range . }}
  - name: {{ . }}
  {{- end }}
{{- end }}
{{- end }}
