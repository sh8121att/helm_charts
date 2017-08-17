# Copyright 2017 The Openstack-Helm Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#-----------------------------------------
# hosts
#-----------------------------------------

# infrastructure services
{{- define "utils.postgresql_host"}}postgresql.{{.Release.Namespace}}{{- end}}


{{- define "utils.joinListWithComma" -}}
{{ range $k, $v := . }}{{ if $k }},{{ end }}{{ $v }}{{ end }}
{{- end -}}

{{- define "utils.template" -}}
{{- $name := index . 0 -}}
{{- $context := index . 1 -}}
{{- $v:= $context.Template.Name | split "/" -}}
{{- $n := len $v -}}
{{- $last := sub $n 1 | printf "_%d" | index $v -}}
{{- $wtf := $context.Template.Name | replace $last $name -}}
{{ include $wtf $context }}
{{- end -}}

{{- define "utils.hash" -}}
{{- $name := index . 0 -}}
{{- $context := index . 1 -}}
{{- $v:= $context.Template.Name | split "/" -}}
{{- $n := len $v -}}
{{- $last := sub $n 1 | printf "_%d" | index $v -}}
{{- $wtf := $context.Template.Name | replace $last $name -}}
{{- include $wtf $context | sha256sum | quote -}}
{{- end -}}


{{- define "utils.kubernetes_entrypoint_init_container" -}}
{{- $envAll := index . 0 -}}
{{- $deps := index . 1 -}}
- name: init
  image: {{ $envAll.Values.images.dep_check }}
  imagePullPolicy: {{ $envAll.Values.images.pull_policy }}
  env:
    - name: POD_NAME
      {{- if $deps.pod }}
      value: {{ index $deps.pod 0 }}
      {{ else }}
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: metadata.name
      {{- end }}
    - name: NAMESPACE
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: metadata.namespace
    - name: INTERFACE_NAME
      value: eth0
    - name: DEPENDENCY_SERVICE
      value: "{{  include "utils.joinListWithComma" $deps.service }}"
    - name: DEPENDENCY_JOBS
      value: "{{  include "utils.joinListWithComma" $deps.jobs }}"
    - name: DEPENDENCY_DAEMONSET
      value: "{{  include "utils.joinListWithComma" $deps.daemonset }}"
    - name: DEPENDENCY_CONTAINER
      value: "{{  include "utils.joinListWithComma" $deps.container }}"
    - name: COMMAND
      value: "echo done"
{{- end -}}
