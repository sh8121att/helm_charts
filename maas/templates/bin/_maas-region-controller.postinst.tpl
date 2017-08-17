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

. /usr/share/debconf/confmodule
db_version 2.0

if [ -f /usr/share/dbconfig-common/dpkg/postinst.pgsql ]; then
    . /usr/share/dbconfig-common/dpkg/postinst.pgsql
fi

RELEASE=`lsb_release -rs` || RELEASE=""

maas_sync_migrate_db(){
    rm -f /var/run/rsyslogd.pid
    service rsyslog restart
    maas-region dbupgrade
}

extract_default_maas_url() {
    # Extract DEFAULT_MAAS_URL IP/host setting from config file $1.
    grep "^DEFAULT_MAAS_URL" "$1" | cut -d"/" -f3
}

configure_migrate_maas_dns() {
    # This only runs on upgrade. We only run this if the
    # there are forwarders to migrate or no
    # named.conf.options.inside.maas are present.
    maas-region edit_named_options \
        --migrate-conflicting-options --config-path \
        /etc/bind/named.conf.options
    invoke-rc.d bind9 restart || true
}

if [ "$1" = "configure" ] && [ -z "$2" ]; then
    #########################################################
    ##########  Configure DEFAULT_MAAS_URL  #################
    #########################################################

    # Obtain IP address of default route and change DEFAULT_MAAS_URL
    # if default-maas-url has not been preseeded.  Prefer ipv4 addresses if
    # present, and use "localhost" only if there is no default route in either
    # address family.
    db_get maas/default-maas-url
    ipaddr="$RET"
    if [ -z "$ipaddr" ]; then
        ipaddr="{{ .Values.ui_service_name }}.{{ .Release.Namespace }}"
    fi
    # Set the IP address of the interface with default route
    db_subst maas/installation-note MAAS_URL "$ipaddr"
    db_set maas/default-maas-url "$ipaddr"

    #########################################################
    ################  Configure Database  ###################
    #########################################################

    # Create the database
    dbc_go maas-region-controller $@

    # Only syncdb if we have selected to install it with dbconfig-common.
    db_get maas-region-controller/dbconfig-install
    if [ "$RET" = "true" ]; then
        maas_sync_migrate_db
        configure_migrate_maas_dns
    fi

    db_get maas/username
    username="$RET"
    if [ -n "$username" ]; then
        db_get maas/password
        password="$RET"
        if [ -n "$password" ]; then
            maas-region createadmin --username "$username" --password "$password" --email "$username@maas"
        fi
    fi

    # Display installation note
    db_input low maas/installation-note || true
    db_go

fi

systemctl enable maas-regiond >/dev/null || true
systemctl restart maas-regiond >/dev/null || true
echo Ready > /var/www/html/readiness.txt
invoke-rc.d apache2 restart || true

db_stop
