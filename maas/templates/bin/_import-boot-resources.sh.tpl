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

set -ex

function check_for_download {

    TIMEOUT={{ .Values.jobs.import_boot_resources.timeout }}
    while [[ ${TIMEOUT} -gt 0 ]]; do
        if maas {{ .Values.conf.maas.credentials.admin_username }} boot-resources is-importing | grep -q 'true';
        then
            echo -e '\nBoot resources currently importing\n'
            let TIMEOUT-={{ .Values.jobs.import_boot_resources.retry_timer }}
            sleep {{ .Values.jobs.import_boot_resources.retry_timer }}
        else
            echo 'Boot resources have completed importing'
            exit 0
        fi
    done
    exit 1

}

KEY=$(maas-region apikey --username={{ .Values.conf.maas.credentials.admin_username }})
maas login {{ .Values.conf.maas.credentials.admin_username }} {{ tuple "maas_region_ui" "default" "region_ui" . | include "helm-toolkit.endpoints.keystone_endpoint_uri_lookup" }} $KEY

# make call to import images
maas {{ .Values.conf.maas.credentials.admin_username }} boot-resources import
# see if we can find > 0 images
sleep {{ .Values.jobs.import_boot_resources.retry_timer }}
check_for_download
