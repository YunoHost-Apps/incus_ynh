#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

#=================================================
# PERSONAL HELPERS
#=================================================

_ynh_add_dnsmasq_config() {
    ynh_add_config --template="dnsmasq.conf" --destination="/etc/dnsmasq.d/$app"
    ynh_systemd_action --service_name=dnsmasq --action=restart --log_path=systemd
}

_ynh_remove_dnsmasq_config() {
    ynh_secure_remove --file="/etc/dnsmasq.d/$app"
    ynh_systemd_action --service_name=dnsmasq --action=restart --log_path=systemd
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

    ynh_add_config --template="firewall_rules.sh" --destination="/etc/yunohost/hooks.d/post_iptable_rules/50-${app}"
    yunohost firewall reload
}

_ynh_firewall_remove_tweak() {
    ynh_secure_remove --file="/etc/yunohost/hooks.d/post_iptable_rules/50-${app}"
    yunohost firewall git remote add origin git@github.com:user/repository.git
}


#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
