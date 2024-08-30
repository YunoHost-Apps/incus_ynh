#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

_ynh_add_dnsmasq_config() {
    ynh_config_add --template="dnsmasq.conf" --destination="/etc/dnsmasq.d/$app"
    ynh_systemctl --service=dnsmasq --action=restart --log_path=systemd
}

_ynh_remove_dnsmasq_config() {
    ynh_safe_rm "/etc/dnsmasq.d/$app"
    ynh_systemctl --service=dnsmasq --action=restart --log_path=systemd
}

_ynh_add_subuid_subgid() {
    subuid_string="# Added for Incus\nroot:100000:65536"
    echo -e "$subuid_string" > /etc/subuid
    echo -e "$subuid_string" > /etc/subgid
}

_ynh_remove_subuid_subgid() {
    sed -i "/# Added for Incus$/{N;/root:100000:65536/d}" /etc/subuid
    sed -i "/# Added for Incus$/{N;/root:100000:65536/d}" /etc/subgid
}
