database_host: {{ include "utils.postgresql_host" . }}
database_name: {{ .Values.database.db_name }}
database_pass: {{ .Values.database.db_password }}
database_user: {{ .Values.database.db_user }}
{{- if .Values.conf.maas.url }}
maas_url: {{ .Values.conf.maas.url }}
{{- else }}
maas_url: http://{{ .Values.ui_service_name }}.{{ .Release.Namespace }}:80/MAAS
{{ end }}