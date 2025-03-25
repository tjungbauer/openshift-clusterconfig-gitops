{{- define "tlsConfig" -}}
tls:
  enable: {{ .tls.enable | default false }}
  insecureSkipVerify: {{ .tls.insecureSkipVerify | default false }}
  {{- if eq (.tls.enable | toString ) "true" }}
  userCert:
    certFile: {{ .tls.userCert.certFile | default "" }}
    certKey: {{ .tls.userCert.certKey | default "" }}
    name: {{ .tls.userCert.name | default "" }}
    namespace: {{ .tls.userCert.namespace | default "" }}
    type: {{ .tls.userCert.type | default "" }}
  caCert:
    {{- if eq (.mode) "Monolithic" }}
    file: {{ .tls.caCert.file | default "service-ca.crt" }}
    {{- else }}
    file: {{ .tls.caCert.file | default "" }}
    {{- end }}
    {{- if eq (.mode) "Monolithic" }}
    name: {{ .tls.caCert.name | default "loki-gateway-ca-bundle" }}
    {{- else }}
    name: {{ .tls.caCert.name | default "" }}
    {{- end }}
    namespace: {{ .tls.caCert.namespace | default "" }}
    {{- if eq (.mode) "Monolithic" }}
    type: {{ .tls.caCert.type | default "configmap" }}
    {{- else }}
    type: {{ .tls.caCert.type | default "" }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "tlsMetricsConfig" -}}
tls:
  type: {{ .tls.type | default "Disabled" }}
  insecureSkipVerify: {{ .tls.insecureSkipVerify | default false }}
  {{- if eq (.tls.type | toString ) "Provided" }}
  provided:
    certFile: {{ .tls.provided.certFile | default "" }}
    certKey: {{ .tls.provided.certKey | default "" }}
    name: {{ .tls.provided.name | default "" }}
    namespace: {{ .tls.provided.namespace | default "" }}
    type: {{ .tls.provided.type | default "" }}
  providedCaFile:
    file: {{ .tls.providedCaFile.file | default "" }}
    name: {{ .tls.providedCaFile.name | default "" }}
    namespace: {{ .tls.providedCaFile.namespace | default "" }}
    type: {{ .tls.providedCaFile.type | default "" }}
  {{- end }}
{{- end }}

{{- define "validate.logLevel" -}}
  {{- if . }}
  {{- if not 
    ( or 
      (eq . "info")
      (eq . "debug")
      (eq . "trace")
      (eq . "warn")
      (eq . "error")
      (eq . "fatal")
      (eq . "panic")
    ) 
  }}
    {{- fail "loglevel must be either trace, debug, info, warn, error, fatal or panic" }}
  {{- end }}
  {{- end }}
{{- end }}

{{- define "validate.deploymentModel" -}}
  {{- $deploymentModel := . | default "" }} 
  {{- if not (or (eq $deploymentModel "Direct") (eq $deploymentModel "Kafka")) }}
    {{- fail "deploymentModel must be either 'Direct' or 'Kafka'" }}
  {{- end }}
{{- end }}