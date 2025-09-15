#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

setup_incus() {
    incus admin init --auto # --storage-backend=dir

    # Set a DNS tld because dnsmasq doesn't seem to like it?
    incus network set incusbr0 dns.domain=incus
}


_set_incus_bridge_ip() {
    incusbr0_ip=$(incus network get incusbr0 ipv4.address | sed 's|/.*||')
    ynh_app_setting_set --key=incusbr0_ip --value="$incusbr0_ip"
}


_ynh_config_add_dnsmasq() {
    ynh_config_add --template="dnsmasq.conf" --destination="/etc/dnsmasq.d/$app"
    ynh_systemctl --service=dnsmasq --action=restart --log_path=systemd
}

_ynh_config_remove_dnsmasq() {
    ynh_safe_rm "/etc/dnsmasq.d/$app"
    ynh_systemctl --service=dnsmasq --action=restart --log_path=systemd
}

_ynh_config_add_subuid_subgid() {
    subuid_string="# Added for Incus\nroot:100000:65536"
    echo -e "$subuid_string" > /etc/subuid
    echo -e "$subuid_string" > /etc/subgid
}

_ynh_config_remove_subuid_subgid() {
    sed -i "/# Added for Incus$/{N;/root:100000:65536/d}" /etc/subuid
    sed -i "/# Added for Incus$/{N;/root:100000:65536/d}" /etc/subgid
}

_ynh_config_add_nftables() {
    ynh_config_add --template="nftables.conf" --destination="/etc/nftables.d/${app}.conf"
    yunohost firewall reload
}

_ynh_config_remove_nftables() {
    ynh_safe_rm "/etc/nftables.d/${app}.conf"
    yunohost firewall reload
}
