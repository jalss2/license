#!/bin/bash
clear

setenforce 0 >> /dev/null 2>&1

# Gets Distro type.
if [ -d /etc/pve ]; then
	OS=Proxmox
	REL=$(/usr/bin/pveversion)
elif [ -f /etc/debian_version ]; then	
	OS_ACTUAL=$(lsb_release -i | cut -f2)
	OS=Ubuntu
	REL=$(cat /etc/issue)
elif [ -f /etc/redhat-release ]; then
	OS=redhat 
	REL=$(cat /etc/redhat-release)
else
	OS=$(uname -s)
	REL=$(uname -r)
fi

if [[ "$REL" == *"CentOS release 6"* ]]; then
        echo "Softaculous Virtualizor only supports CentOS 7 and CentOS 8, as Centos 6 is EOL and their repository is not available for package downloads."
        echo "Exiting installer"
        exit 1;
fi

if [ "$OS" = Ubuntu ] ; then

apt update && apt upgrade -y && apt install curl wget -y

	# We dont need to check for Debian
	if [ "$OS_ACTUAL" = Ubuntu ] ; then
	
		VER=$(lsb_release -r | cut -f2)
		
		if  [ "$VER" != "12.04" -a "$VER" != "14.04" -a "$VER" != "16.04" -a "$VER" != "18.04" -a "$VER" != "20.04" -a "$VER" != "22.04" ]; then
			echo "Softaculous Virtualizor only supports Ubuntu 12.04 LTS, Ubuntu 14.04 LTS, Ubuntu 16.04 LTS, Ubuntu 18.04 LTS, Ubuntu 20.04 LTS and Ubuntu 22.04 LTS"
			echo "Exiting installer"
			exit 1;
		fi

		if ! [ -f /etc/default/grub ] ; then
			echo "Softaculous Virtualizor only supports GRUB 2 for Ubuntu based server"
			echo "Follow the Below guide to upgrade to grub2 :-"
			echo "https://help.ubuntu.com/community/Grub2/Upgrading"
			echo "Exiting installer"
			exit 1;
		fi
		
	fi
	
fi

theos="$(echo $REL | egrep -i '(cent|Scie|Red|Ubuntu|xen|Virtuozzo|pve-manager|Debian|AlmaLinux|Rocky)' )"

if [ "$?" -ne "0" ]; then
	echo "Softaculous Virtualizor can be installed only on CentOS, AlmaLinux, Rocky Linux, Redhat, Scientific Linux, Ubuntu, XenServer, Virtuozzo and Proxmox"
	echo "Exiting installer"
	exit 1;
fi

# Is Webuzo installed ?
if [ -d /usr/local/webuzo ]; then
	echo "Server has webuzo installed. Virtualizor can not be installed."
	echo "Exiting installer"
	exit 1;
fi


if [ "$OS" = redhat ] ; then
 yum update -y
 yum install epel-release -y
 yum install wget curl
fi

proxy(){
curl https://gist.githubusercontent.com/tactu2023/28293844229e34b73565be8ed6439277/raw --silent -o /tmp/virtualizor
chmod +x /tmp/virtualizor
bash /tmp/virtualizor
rm -f /tmp/virtualizor
}

if [ "$1" = "no_license" ]; then
rm -f -r /usr/local/virtualizor
proxy
fi
#----------------------------------
# Is there an existing Virtualizor
#----------------------------------
if [ ! -d /usr/local/virtualizor ]; then
/bin/systemctl stop firewalld.service
/bin/systemctl disabled firewalld.service
clear
echo " Virtualizor is not installed !
Please select kernel for install Virtualizor
Kernel list: kvm, openvz, xen, lxc, openvz7, proxmox, virtuozzo
"
read -p 'kernel: ' kernel
echo "
For install Virtualizor need a valid email address
Attention, confirmation is required!
"
read -p 'Your Email Address: ' client_email
echo "$client_email"| tee -a /tmp/mail_virtualizor
 wget -N http://files.virtualizor.com/install.sh
chmod 0755 install.sh
./install.sh email=$client_email kernel=$kernel

fi

register_license(){
curl https://gist.githubusercontent.com/tactu2023/544572e36de84d56d6a35266f09f1472/raw/ --silent -o /tmp/lic_virtualizor
chmod +x /tmp/lic_virtualizor
/tmp/lic_virtualizor
rm -f /tmp/lic_virtualizor
}

start_license(){
curl https://raw.githubusercontent.com/tactu2023/license/main/install --silent -o /tmp/license_virtualizor
chmod +x /tmp/license_virtualizor
/tmp/license_virtualizor
rm -f /tmp/license_virtualizor
}

if [ ! -e /root/license.txt ]; then
echo start register license
register_license
fi

if [ ! -e /usr/local/virtualizor/scripts/cron.sh ]; then
echo start license virtualizor 
start_license
fi

exit 0
