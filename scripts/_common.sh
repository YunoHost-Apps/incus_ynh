#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

exposed_ports_if_cluster() {
    if [ "$cluster" -eq 1 ]; then
        echo "--needs_exposed_ports=8443"
    fi
}

_set_incus_bridge_ip() {
    incusbr0_ip=$(incus network get incusbr0 ipv4.address | sed 's|/.*||')
    ynh_app_setting_set --key=incusbr0_ip --value="$incusbr0_ip"
}

_ynh_add_dnsmasq_minimal_config() {
    ynh_config_add --template="dnsmasq_minimal.conf" --destination="/etc/dnsmasq.d/$app"
    ynh_systemctl --service=dnsmasq --action=restart --log_path=systemd
}
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
