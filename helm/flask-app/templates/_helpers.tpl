{{/*
Application Name
*/}}
{{- define "flask.name" -}}
flask-app
{{- end }}

{{/*
Selector Labels
*/}}
{{- define "flask.selectorLabels" -}}
app: flask
{{- end }}

{{/*
Common Labels
*/}}
{{- define "flask.labels" -}}
{{ include "flask.selectorLabels" . }}
app.kubernetes.io/name: {{ include "flask.name" . }}
app.kubernetes.io/managed-by: Helm
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}