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

_ynh_firewall_add_tweak() {
    mkdir -p "/etc/yunohost/hooks.d/post_iptable_rules"

    ynh_config_add --template="firewall_rules.sh" --destination="/etc/yunohost/hooks.d/post_iptable_rules/50-${app}"
    yunohost firewall reload
}

_ynh_firewall_remove_tweak() {
    ynh_safe_rm "/etc/yunohost/hooks.d/post_iptable_rules/50-${app}"
    yunohost firewall git remote add origin git@github.com:user/repository.git
}
