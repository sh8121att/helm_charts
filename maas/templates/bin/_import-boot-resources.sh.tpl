#!/bin/sh

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

set -ex

function check_for_download {

    TIMEOUT={{ .Values.jobs.import_boot_resources.timeout }}
    while [[ ${TIMEOUT} -gt 0 ]]; do
        if maas {{ .Values.credentials.admin_username }} boot-resources read | grep 'Synced'
        then
            echo 'Boot resources found'
            exit 0
        else
            echo 'Did not find boot resources.  Will try again'
            let TIMEOUT-={{ .Values.jobs.import_boot_resources.retry_timer }}
            sleep {{ .Values.jobs.import_boot_resources.retry_timer }}        
        fi
    done
    exit 1
}

KEY=$(maas-region apikey --username={{ .Values.credentials.admin_username }})
maas login {{ .Values.credentials.admin_username }} http://{{ .Values.ui_service_name }}.{{ .Release.Namespace }}/MAAS/ $KEY

# make call to import images
maas {{ .Values.credentials.admin_username }} maas set-config name=enable_http_proxy value={{ .Values.conf.maas.proxy.enabled }}
maas {{ .Values.credentials.admin_username }} maas set-config name=http_proxy value={{ .Values.conf.maas.proxy.server }}
maas {{ .Values.credentials.admin_username }} maas set-config name=ntp_servers value={{ .Values.conf.maas.ntp.servers | quote }}
maas {{ .Values.credentials.admin_username }} maas set-config name=ntp_external_only value={{ .Values.conf.maas.ntp.external_only }}
maas {{ .Values.credentials.admin_username }} maas set-config name=dnssec_validation value={{ .Values.conf.maas.dns.dnssec_required }}
maas {{ .Values.credentials.admin_username }} maas set-config name=upstream_dns value={{ .Values.conf.maas.dns.upstream_servers | quote }}
maas {{ .Values.credentials.admin_username }} boot-resources import
# see if we can find > 0 images
sleep {{ .Values.jobs.import_boot_resources.retry_timer }}
check_for_download
