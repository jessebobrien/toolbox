#! /bin/bash

# VERSION 1.0
# Written by Jesse O'Brien
# 12/02/2009

# exit on errors, return the last line
set -e

GetVersionFromFile()
{
	VERSION=`cat $1 | tr "\n" ' ' | sed s/.*VERSION.*=\ //`
}

if [ "$(id -u)" != "0" ]; then
	echo "You are not root.  Try using sudo" 1>&2
	exit 1
fi

# is it already installed?
if [ -d /usr/local/xrdp/ ]; then
	echo "File /usr/local/xrdp/xrdp_control.sh already exists!  Installation should not be necessary."
	exit 1
else
	echo "XRDP does not appear to be installed, proceeding normally."
fi

# determine operating system
OS=`uname -s`
REV=`uname -r`
MACH=`uname -m`

echo "Determining operating system for dependency installation..."
if [ "${OS}"="Linux" ] ; then
	KERNEL=`uname -r`
	if [ -f /etc/redhat-release ] ; then
		DIST='RedHat'
		PSEUDONAME=`cat /etc/redhat-release | sed s/.*\(// | sed s/\)//`
		REV=`cat /etc/redhat-release | sed s/.*release\ // | sed s/\ .*//`
	elif [ -f /etc/SUSE-release ] ; then
		DIST=`cat /etc/SUSE-release | tr "\n" ' '| sed s/VERSION.*//`
		REV=`cat /etc/SUSE-release | tr "\n" ' ' | sed s/.*=\ //`
	elif [ -f /etc/debian_version ] ; then
		DIST="Debian"
		REV=''
	elif [ -f /etc/UnitedLinux-release ] ; then
		DIST="${DIST}[`cat /etc/UnitedLinux-release | tr "\n" ' ' | sed s/VERSION.*//`]"
	fi

	OSSTR="${OS} ${DIST} ${REV} (${PSUEDONAME} ${KERNEL} ${MACH})"
else
	echo "You don't appear to be running a Linux environment.  Cannot continue."
fi

echo "OSSTR: "${OSSTR}
echo "Reported Distribution: "${DIST}
	
# install make, openssl-devel, vncserver, gcc and pam-devel
echo "Installing dependencies using built-in package manager, please respond to any prompts."
if [ "${DIST}" = "Debian" ] ; then
	apt-get update
	apt-get install libcurl4-openssl-dev libpam0g-dev make vnc4server gcc
elif [ "${DIST}" = "RedHat" ] ; then
	yum update
	yum install openssl-devel pam-devel make vnc-server gcc
elif [ "${DIST}" = "SUSE" ] ; then
	yast -i openssl-devel pam-devel make vncserver gcc
else echo "***I don't know what to do with " ${OSSTR} "so I am not installing any dependencies automatically.***"
fi

# copy and extract source from Samba, should prompt for password
echo "Connecting to Samba Server and copying source code to temporary installation directory."
scp imguser@172.16.2.11:/home/office/images/imaging_tools/Xrdp/* /tmp/
cd /tmp/
echo 'extracting from :' & pwd
mkdir -p /tmp/xrdp/
tar -zxvf /tmp/xrdp*.tar.gz -C /tmp/xrdp/
echo 'finished extracting'
mv /tmp/xrdp/xrdp*/* /tmp/xrdp/
echo 'Building xrdp...'
cd /tmp/xrdp
make
echo "Installing xrdp..."
make install
echo "Installation complete"

# cleanup after install
echo "Removing temporary install files"
if [ -d /tmp/xrdp ]; then
	rm -rf /tmp/xrdp/
	
elif 
	echo 

# automatically start services
echo "Setting up autostart"
if [ "${DIST}" = "Debian" ] ; then
	echo "using update-rc.d"
	ln -s /usr/local/xrdp/xrdp_control.sh /etc/init.d/xrdp
	update-rc.d xrdp defaults
elif [ "${DIST}" = "RedHat" ] ; then
	echo "adding to rc.local"
	echo "/usr/local/xrdp/xrdp_control.sh start" >> /etc/rc.local
elif [ "${DIST}" = "SUSE" ] ; then
	echo "adding to rc.local"
	echo "/usr/local/xrdp/xrdp_control.sh start" >> /etc/rc.local
else echo "***I don't know how to autostart on " ${OSSTR} "so startup should be configured manually.***"
fi

echo "Installation complete.  You can test this setup by restarting the machine and logging in using an RDP viewer, or start the service manually using /usr/local/xrdp/xrdp_control.sh start"
