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

{{/*
Secret wiring for the API bootstrap credentials.

The chart ships no credential defaults. A `rootPassword` / `jwtSecret` published in
a public repository is a cluster-compromise path, so rendering fails closed instead
of installing a known-bad value (helm-charts#37, core#93). Thresholds mirror the API
validation in core#108: root password >= 12 chars, JWT secret >= 32 chars.
*/}}
{{- define "virtfoundry.secretName" -}}
{{- if .Values.secrets.existingSecret -}}
{{- .Values.secrets.existingSecret -}}
{{- else -}}
{{- printf "%s-secrets" .Values.fullnamePrefix -}}
{{- end -}}
{{- end }}

{{- define "virtfoundry.rootPasswordKey" -}}
{{- .Values.secrets.rootPasswordKey | default "ROOT_PASSWORD" -}}
{{- end }}

{{- define "virtfoundry.jwtSecretKey" -}}
{{- .Values.secrets.jwtSecretKey | default "JWT_SECRET" -}}
{{- end }}

{{/*
Read a key back from the chart-managed Secret that is already in the cluster so an
upgrade keeps the current credential instead of resetting it. Empty during
`helm template` and on a first install — callers must handle that.
*/}}
{{- define "virtfoundry.liveSecretValue" -}}
{{- $ctx := .ctx -}}
{{- $name := .name | default (printf "%s-secrets" $ctx.Values.fullnamePrefix) -}}
{{- $live := lookup "v1" "Secret" $ctx.Values.namespace $name -}}
{{- if and $live $live.data (hasKey $live.data .key) -}}
{{- index $live.data .key | b64dec -}}
{{- end -}}
{{- end }}

{{- define "virtfoundry.rootPassword" -}}
{{- $key := include "virtfoundry.rootPasswordKey" . -}}
{{- $value := .Values.secrets.rootPassword | default "" | toString -}}
{{- if not $value -}}
{{- $value = include "virtfoundry.liveSecretValue" (dict "ctx" . "key" $key) -}}
{{- end -}}
{{- if .Values.secrets.allowInsecureDefaults -}}
{{- $value -}}
{{- else -}}
{{- if not $value -}}
{{- fail (printf "secrets.rootPassword is required (min 12 chars). The chart ships no default root password: set --set secrets.rootPassword=... or point secrets.existingSecret at a Secret holding key %s. See helm-charts#37." $key) -}}
{{- end -}}
{{- if eq (lower $value) "virtfoundry" -}}
{{- fail "secrets.rootPassword matches the published default \"virtfoundry\" and is rejected. Pick a unique password of at least 12 characters (helm-charts#37, core#93)." -}}
{{- end -}}
{{- if lt (len $value) 12 -}}
{{- fail (printf "secrets.rootPassword is too short (%d chars); the API requires at least 12 (core#108)." (len $value)) -}}
{{- end -}}
{{- $value -}}
{{- end -}}
{{- end }}

{{/*
JWT secret resolution order: explicit value -> value already stored in the live
Secret -> random 48-char secret when secrets.autoGenerateJwtSecret is enabled.
The live lookup is what keeps `helm upgrade` from invalidating issued tokens.
*/}}
{{- define "virtfoundry.jwtSecret" -}}
{{- $key := include "virtfoundry.jwtSecretKey" . -}}
{{- $value := .Values.secrets.jwtSecret | default "" | toString -}}
{{- if not $value -}}
{{- $value = include "virtfoundry.liveSecretValue" (dict "ctx" . "key" $key) -}}
{{- end -}}
{{- if and (not $value) .Values.secrets.autoGenerateJwtSecret -}}
{{- if .Release.IsUpgrade -}}
{{- fail (printf "secrets.autoGenerateJwtSecret is enabled but the live Secret %s-secrets could not be read, so upgrading would rotate the JWT secret and invalidate every issued token. Run the upgrade against the cluster (lookup needs an API connection; client-side --dry-run cannot see it) or set secrets.jwtSecret / secrets.existingSecret explicitly." .Values.fullnamePrefix) -}}
{{- else -}}
{{- $value = randAlphaNum 48 -}}
{{- end -}}
{{- end -}}
{{- if .Values.secrets.allowInsecureDefaults -}}
{{- $value -}}
{{- else -}}
{{- if not $value -}}
{{- fail (printf "secrets.jwtSecret is required (min 32 chars). Set --set secrets.jwtSecret=\"$(openssl rand -hex 32)\", point secrets.existingSecret at a Secret holding key %s, or enable secrets.autoGenerateJwtSecret on a cluster-connected install. See helm-charts#37." $key) -}}
{{- end -}}
{{- if has (lower $value) (list "change-me-in-production" "dev-secret-change-in-prod") -}}
{{- fail "secrets.jwtSecret matches a published default HMAC key and is rejected: anyone could forge platform tokens. Generate one with `openssl rand -hex 32` (helm-charts#37, core#93)." -}}
{{- end -}}
{{- if lt (len $value) 32 -}}
{{- fail (printf "secrets.jwtSecret is too short (%d chars); the API requires at least 32 (core#108)." (len $value)) -}}
{{- end -}}
{{- $value -}}
{{- end -}}
{{- end }}

{{/*
Entry point for the credential checks, included from secret.yaml so they run on
every render. With secrets.existingSecret the Secret is not rendered, so the checks
inspect the referenced Secret instead — best effort, since `lookup` is empty during
`helm template` and client-side dry-runs.
*/}}
{{- define "virtfoundry.validateSecrets" -}}
{{- if .Values.secrets.existingSecret -}}
{{- include "virtfoundry.validateExistingSecret" . -}}
{{- else -}}
{{- $_ := include "virtfoundry.rootPassword" . -}}
{{- $_ = include "virtfoundry.jwtSecret" . -}}
{{- end -}}
{{- end }}

{{- define "virtfoundry.validateExistingSecret" -}}
{{- $name := .Values.secrets.existingSecret -}}
{{- $live := lookup "v1" "Secret" .Values.namespace $name -}}
{{- if and $live (not .Values.secrets.allowInsecureDefaults) -}}
{{- $rootKey := include "virtfoundry.rootPasswordKey" . -}}
{{- $jwtKey := include "virtfoundry.jwtSecretKey" . -}}
{{- $data := $live.data | default dict -}}
{{- if not (hasKey $data $rootKey) -}}
{{- fail (printf "secrets.existingSecret %q has no key %q; create it or set secrets.rootPasswordKey." $name $rootKey) -}}
{{- end -}}
{{- if not (hasKey $data $jwtKey) -}}
{{- fail (printf "secrets.existingSecret %q has no key %q; create it or set secrets.jwtSecretKey." $name $jwtKey) -}}
{{- end -}}
{{- $root := index $data $rootKey | b64dec -}}
{{- $jwt := index $data $jwtKey | b64dec -}}
{{- if or (eq (lower $root) "virtfoundry") (lt (len $root) 12) -}}
{{- fail (printf "secrets.existingSecret %q key %q is a published default or shorter than 12 chars; rotate it before installing (helm-charts#37)." $name $rootKey) -}}
{{- end -}}
{{- if or (has (lower $jwt) (list "change-me-in-production" "dev-secret-change-in-prod")) (lt (len $jwt) 32) -}}
{{- fail (printf "secrets.existingSecret %q key %q is a published default or shorter than 32 chars; rotate it before installing (helm-charts#37)." $name $jwtKey) -}}
{{- end -}}
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
