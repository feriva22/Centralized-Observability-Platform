{{- define "kafka-native.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kafka-native.fullname" -}}
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

{{- define "kafka-native.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "kafka-native.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "kafka-native.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kafka-native.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "kafka-native.podLabels" -}}
{{ include "kafka-native.selectorLabels" . }}
{{- with .Values.podLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "kafka-native.containerEnv" -}}
{{- $defaultEnv := .env -}}
{{- $customEnv := .ctx.Values.env -}}
{{- $merged := list -}}
{{- range $defaultEnv -}}
  {{- $found := false -}}
  {{- range $customEnv -}}
    {{- if eq .name $.name -}}
      {{- $merged = append $merged . -}}
      {{- $found = true -}}
    {{- end -}}
  {{- end -}}
  {{- if not $found -}}
    {{- $merged = append $merged . -}}
  {{- end -}}
{{- end -}}
{{- range $customEnv -}}
  {{- $found := false -}}
  {{- range $defaultEnv -}}
    {{- if eq .name $.name -}}
      {{- $found = true -}}
    {{- end -}}
  {{- end -}}
  {{- if not $found -}}
    {{- $merged = append $merged . -}}
  {{- end -}}
{{- end -}}
env:
{{ toYaml $merged | indent 2 -}}
{{- with .ctx.Values.extraEnvFrom }}
envFrom:
{{ toYaml . | indent 2 }}
{{- end }}
{{- end }}
