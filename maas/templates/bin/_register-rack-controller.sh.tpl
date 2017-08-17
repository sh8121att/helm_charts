#!/bin/bash

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

{{- if empty .Values.conf.maas.url.maas_url -}}
{{- tuple "maas_region_ui" "default" "region_ui" . | include "helm-toolkit.endpoints.keystone_endpoint_uri_lookup" | set .Values.conf.maas.url "maas_url" | quote | trunc 0 -}}
{{- end -}}
set -ex

# show env
env > /tmp/env

echo "register-rack-controller URL: "{{ .Values.conf.maas.url.maas_url }}

# note the secret must be a valid hex value

# register forever
while [ 1 ];
do
  if maas-rack register --url={{ .Values.conf.maas.url.maas_url }} --secret={{ .Values.secrets.maas_region.value | quote }};
  then
    echo "Successfully registered with MaaS Region Controller"
  break
  else
    echo "Unable to register with {{ .Values.conf.maas.url.maas_url }}... will try again"
        sleep 10
  fi;

done;
