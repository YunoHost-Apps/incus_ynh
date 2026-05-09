#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

setup_incus() {
    if [ "$cluster" -eq 1 ]; then
        yunohost firewall allow TCP 8443

        free_space=$(df --output=avail / | sed 1d)
        btrfs_size=$(( free_space * 90 / 100 / 1024 / 1024 ))
        incus_network=$((1 + RANDOM % 254))
        ynh_config_add --template="incus-preseed-cluster.yml" --destination="/tmp/incus-preseed-cluster.yml"
        incus admin init --preseed < "/tmp/incus-preseed-cluster.yml"
        ynh_safe_rm "/tmp/incus-preseed-cluster.yml"

        incus config set core.https_address "[::]"
    else
        incus admin init --auto # --storage-backend=dir
    fi

    # Set a DNS tld because dnsmasq doesn't seem to like it?
    incus network set incusbr0 dns.domain=incus
}

exposed_ports_if_cluster() {
    if [ "$cluster" -eq 1 ]; then
        echo "--needs_exposed_ports=8443"
    fi
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
