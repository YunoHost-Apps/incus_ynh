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
        ynh_add_config --template="incus-preseed-cluster.yml" --destination="/tmp/incus-preseed-cluster.yml"
        incus admin init --preseed < "/tmp/incus-preseed-cluster.yml"
        rm "/tmp/incus-preseed-cluster.yml"
    else
        incus admin init --auto # --storage-backend=dir
    fi

    # Set a DNS tld because dnsmasq doesn't seem to like it?
    incus network set incusbr0 dns.domain=incus
    incus config set core.https_address :$port
    openssl req -x509 -newkey rsa:2048 -keyout $data_dir/client.key -nodes -out $data_dir/client.crt -subj "/CN=incus.local"
    incus config trust add-certificate $data_dir/client.crt
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
