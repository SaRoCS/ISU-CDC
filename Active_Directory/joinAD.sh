#!/bin/bash

read -p "Box name: " box_name
read -p "AD server IP: " ad_ip
read -p "Team number: " team_num

hostnamectl set-hostname $box_name.team$team_num.isucdc.com
# Ubuntu <18 hosts has 127.0.1.1    name instead of 127.0.1.1 name
sed -i "/$box_name/a $ad_ip ad.team$team_num.isucdc.com ad" /etc/hosts
apt update
apt full-upgrade -y
apt install -y realmd ntp
sed -i "/pool 0.ubuntu.pool.ntp.org iburst/i server ad.team$team_num.isucdc.com" /etc/ntp.conf
realm discover team$team_num.isucdc.com
sleep 5
# all but krb5-user for Ubuntu version <20
apt install -y krb5-user sssd-tools sssd libnss-sss libpam-sss adcli samba-common-bin
# enter TEAM5.ISUCDC.COM
kinit administrator
# --install=/ is for Ubuntu version <20
realm join team$team_num.isucdc.com --install=/
sleep 5
sed -i 's/use_fully_qualified_names = True/use_fully_qualified_names = False/' /etc/sssd/sssd.conf
service sssd --full-restart
sed -i "/pam_unix.so/a session required\tpam_mkhomedir.so skel=/etc/skel/ umask=0022" /etc/pam.d/common-session
sed -i "/%admin ALL=(ALL) ALL/a \\\n# Allow Domain Admins to use sudo\n%Domain\\\ Admins ALL=(ALL) NOPASSWD:ALL\n%Administrators ALL=(ALL) NOPASSWD:ALL" /etc/sudoers
# realm permit -g group@domain
realm permit --all
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
service ssh restart
reboot
