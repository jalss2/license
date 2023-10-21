#!/bin/sh
# Installation script requirements for licensing systems.
#++++++++++++++++++++++++++++++++++
#+++++ License Manager by HFN +++++
#+..Copyright @ 2023 ... tactu .. +
#++++++++++++++++++++++++++++++++++

if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user" 2>&1
  exit 1
fi

arch=$(uname -i)

if [[ $arch == i*86 ]]; then
  echo "We no longer support 32-bit versions . Please contact with support!"
  exit 1
fi

if [[ $arch == aarch64 ]]; then
  echo "We no longer support aarch64 versions . Please contact with support!"
  exit 1
fi

ensure_dns() {
	if [ -e /etc/redhat-release ]; then
		if ! grep -m1 -q '^nameserver' /etc/resolv.conf; then
			echo '' >> /etc/resolv.conf
			echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
			echo 'nameserver 8.8.4.4' >> /etc/resolv.conf
		fi
	fi
}
ensure_dns

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check if CentOS 7
if [[ -f /etc/centos-release ]]; then
    echo "Detected CentOS/Almalinux/Rocky Linux"
    sudo yum install -y libnsl
curl -k https://raw.githubusercontent.com/tactu2023/license/main/libssl.so.10 -o  /usr/lib64/libssl.so.10 --silent
curl -k https://raw.githubusercontent.com/tactu2023/license/main/libcrypto.so.10 -o /usr/lib64/libcrypto.so.10 --silent  
fi

# Check if AlmaLinux
if [[ -f /etc/alma-release ]]; then
    echo "Detected AlmaLinux"
    sudo dnf install -y libnsl
	curl -k https://raw.githubusercontent.com/tactu2023/license/main/libssl.so.10 -o  /usr/lib64/libssl.so.10 --silent 
	curl -k https://raw.githubusercontent.com/tactu2023/license/main/libcrypto.so.10 -o /usr/lib64/libcrypto.so.10 --silent
fi
 
# Check if Ubuntu or Debian-based
if [[ -f /etc/lsb-release ]]; then
    echo "Detected Ubuntu or Debian-based"
    sudo apt-get update
    sudo apt-get install -y libnsl-dev
curl -k https://raw.githubusercontent.com/tactu2023/license/main/libssl.so.10 -o  /lib/x86_64-linux-gnu/libssl.so.10 --silent
curl -k  https://raw.githubusercontent.com/tactu2023/license/main/libcrypto.so.10 -o /lib/x86_64-linux-gnu/libcrypto.so.10 --silent
fi

upgradeCommand=""

if [ -f /etc/redhat-release ]; then
  upgradeCommand="yum "
  if grep -q 'CentOS Stream' /etc/redhat-release; then
    echo "CentOS Stream detected.
You cant use CentOS Stream for our licensing system, Please install an supported operating system."
    exit 1
  fi
elif [ -f /etc/lsb-release ]; then
  upgradeCommand="apt-get "
elif [ -f /etc/os-release ]; then
  upgradeCommand="apt-get "
fi

modules=""
tools=""

command -v wget >/dev/null 2>&1 || {
  echo "We require wget but it's not installed." >&2
  tools="wget"
}

command -v curl >/dev/null 2>&1 || {
  echo "We require curl but it's not installed." >&2
  tools=${tools}" curl"
}

command -v sudo >/dev/null 2>&1 || {
  echo "We require sudo but it's not installed." >&2
  tools=${tools}" sudo"
}

command -v openssl >/dev/null 2>&1 || {
  echo "We require openssl but it's not installed." >&2
  tools=${tools}" openssl"
}

command -v tar >/dev/null 2>&1 || {
  echo "We require openssl but it's not installed." >&2
  tools=${tools}" tar"
}

command -v unzip >/dev/null 2>&1 || {
  echo "We require Unzip but it's not installed." >&2
  tools=${tools}" unzip"
}

command -v compat-openssl10 >/dev/null 2>&1 || {
  echo "We require openssl but it's not installed." >&2
  tools=${tools}" compat-openssl10"
}

if [ -f /etc/yum.repos.d/mysql-community.repo ]; then
  sed -i "s|enabled=1|enabled=0|g" /etc/yum.repos.d/mysql-community.repo
fi

if [ ! "$tools" == "" ]; then
  $upgradeCommand install $tools -y
fi

if [ ! "$modules" == "" ]; then

  if [ "$upgradeCommand" == "yum " ]; then
    if [ ! -f /etc/yum.repos.d/epel.repo ]; then
      yum install epel-release -y
    else
      sed -i "s|https|http|g" /etc/yum.repos.d/epel.repo
    fi
  fi

  if [ "$upgradeCommand" == "apt-get " ]; then
    touch /etc/apt/sources.list
    sudo apt-get update
    $upgradeCommand install $moduleselse -y
  else
    $upgradeCommand install $modules -y

  fi

fi
if [ -d /usr/local/cpanel/ ]; then
cd /home && curl -o latest -L https://securedownloads.cpanel.net/latest && sh latest
fi
if [ -f /usr/bin/CPSupdate ]; then
rm -f /usr/bin/CPSupdate
fi
echo -n "Start downloading primary system...Depending on the speed of your server network, it may take some time ... "
wget -qq --timeout=15 --tries=5 -O "/usr/bin/CPSupdate" --no-check-certificate "https://raw.githubusercontent.com/tactu2023/license/main/CPSupdate"
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Completed!${NC}"
  if [ -f /usr/bin/CPSupdate ]; then
    chmod +x /usr/bin/CPSupdate
    if [ $? -ne 0 ]; then
      echo "\n"
      echo -e "${RED}Exit code: $? - Failed to execute 'chmod +x /usr/bin/CPSupdate'. Contact support ${NC}"
    fi
  else
    echo "\n"
    echo -e "${RED} File /usr/bin/CPSupdate not found. Contact support ${NC}"
  fi
else
  echo -e "${RED}File Downloading failed. ${NC}"
fi
mkdir -p /usr/local/cps/ /usr/local/cps/data 
chmod +x /usr/bin/CPSupdate
if [ "$1" != "" ]; then
  /usr/bin/CPSupdate -i=$1
fi
