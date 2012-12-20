#!/bin/bash

# Settings
NETWORKADAPTER="eth1"
NETWORKSTATICIP="10.10.1.x"
NETWORKGATEWAY="10.10.1.1"
NETWORKNETMASK="255.255.255.0"

TMPRAM="/tmpram"
RAMRUN=1 # Comment to disable /var/run in RAM
RAMLOCK=1 # Comment to disable /var/lock in RAM
NOATIME=1 # Comment to disable added noatime to root in /etc/fstab

MAIL_ENABLE=1 # Comment to disable exim4 config
MAIL_DOMAIN=""
MAIL_HOSTNAME=`hostname`

echo "Edit the script before running it."
exit 1

# /dev/shm
echo "Symlinking $TMPRAM to /dev/shm."
ln -s /dev/shm $TMPRAM

# Update network adapter
echo "Updating network interfaces..."

INTERFACEFILE="/etc/network/interfaces"
echo "" >> $INTERFACEFILE
echo "# Host-Only adapter" >> $INTERFACEFILE
echo "auto $NETWORKADAPTER" >> $INTERFACEFILE
echo "iface $NETWORKADAPTER inet static" >> $INTERFACEFILE
echo "    address $NETWORKSTATICIP" >> $INTERFACEFILE
echo "    netmask $NETWORKNETMASK" >> $INTERFACEFILE
echo "    gateway $NETWORKGATEWAY" >> $INTERFACEFILE

echo "Updated network interfaces."
echo "Activating network interface "$NETWORKADAPTER"..."
ifup $NETWORKADAPTER
echo "Activated network interface "$NETWORKADAPTER"."

# Dotdeb repo
echo "Installing dotdeb repository..."
SOURCES="/etc/apt/sources.list"
echo "" >> $SOURCES
echo "# Dotdeb" >> $SOURCES
echo "deb http://packages.dotdeb.org squeeze all" >> $SOURCES
echo "deb-src http://packages.dotdeb.org squeeze all" >> $SOURCES

wget -O  $TMPRAM/dotdeb.gpg http://www.dotdeb.org/dotdeb.gpg
cat $TMPRAM/dotdeb.gpg | apt-key add -
rm  $TMPRAM/dotdeb.gpg

echo "Installed dotdeb repository."

# Debian Backports
echo "Installing Debian Backports repository..."
echo "" >> $SOURCES
echo "# Debian Backports" >> $SOURCES
echo "deb http://backports.debian.org/debian-backports squeeze-backports main" >> $SOURCES
echo "Installed Debian Backports repository."

# apt-get update
echo "Executing apt-get update..."

apt-get update

echo "Done."

# mpt-statusd
# Floods various logs with "mpt-statusd: detected non-optimal RAID status"
echo "Disabling mpt-statusd..."
/etc/init.d/mpt-statusd stop
update-rc.d-insserv -f mpt-statusd remove
echo "Disabled mpt-statusd."

# crontab
echo "Installing crontab template."
echo "MAILTO=\"\"
SHELL=/bin/bash

#minute (0-59)
#|	hour (0-23)
#|	|   day of the month (1-31)
#|	|	|   month of the year (1-12 or Jan-Dec)
#|	|	|	|   day of the week (0-6 with 0=Sun or Sun-Sat)
#|	|	|	|	|	commands
#|	|	|	|	|	|

# Other crons
" > $TMPRAM/cron.template

crontab $TMPRAM/cron.template

# RAMRUN
if [ $RAMRUN ] && grep -Fxq "RAMRUN=no" /etc/default/rcS ; then
    echo "Enabling RAMRUN..."
    
    sed -i 's/RAMRUN=no/RAMRUN=yes/g' /etc/default/rcS
    
    echo "Done."
fi;

# RAMLOCK
if [ $RAMLOCK ] && grep -Fxq "RAMLOCK=no" /etc/default/rcS ; then
    echo "Enabling RAMLOCK..."
    
    sed -i 's/RAMLOCK=no/RAMLOCK=yes/g' /etc/default/rcS
    
    echo "Done."
fi

# NOATIME
if [ $NOATIME ]; then
    echo "Adding noatime..."
    
    cp /etc/fstab $TMPRAM/fstab
    
    sed -i 's/errors=remount-ro/errors=remount-ro,noatime/g' $TMPRAM/fstab
    
    echo "Previewing changes..."
    nano $TMPRAM/fstab
    
    echo "Write changes to /etc/fstab? (y/N)"
    
    fstabloop=1
    
    while [ $fstabloop -eq 1 ]; do
        read RESPONSE;
        case "$RESPONSE" in
            [yY]|[yY][eE][sS])
                echo "Copying /etc/fstab to /etc/fstab.bak..."
                cp /etc/fstab /etc/fstab.bak
                
                echo "Writing changes to /etc/fstab..."
                cp $TMPRAM/fstab /etc/fstab
                rm $TMPRAM/fstab
                
                echo "Done."
                fstabloop=0
                ;;
            [nN]|[nN][oO]|"")
                echo "Not saving changes..."
                rm $TMPRAM/fstab
                
                fstabloop=0
                ;;
            *)
                echo "Write changes to /etc/fstab? (y/N)"
                ;;
        esac
    done
fi

# Exim4 config
if [ $MAIL_ENABLE ]; then
    echo "Updating exim4 config..."
    cp /etc/exim4/update-exim4.conf.conf /etc/exim4/update-exim4.conf.conf.bak
    echo "# /etc/exim4/update-exim4.conf.conf
#
# Edit this file and /etc/mailname by hand and execute update-exim4.conf
# yourself or use 'dpkg-reconfigure exim4-config'
#
# Please note that this is _not_ a dpkg-conffile and that automatic changes
# to this file might happen. The code handling this will honor your local
# changes, so this is usually fine, but will break local schemes that mess
# around with multiple versions of the file.
#
# update-exim4.conf uses this file to determine variable values to generate
# exim configuration macros for the configuration file.
#
# Most settings found in here do have corresponding questions in the
# Debconf configuration, but not all of them.
#
# This is a Debian specific file

dc_eximconfig_configtype='internet'
dc_other_hostnames='$MAIL_HOSTNAME'
dc_local_interfaces='127.0.0.1 ; ::1'
dc_readhost='$MAIL_DOMAIN'
dc_relay_domains=''
dc_minimaldns='false'
dc_relay_nets=''
dc_smarthost=''
CFILEMODE='644'
dc_use_split_config='false'
dc_hide_mailname='true'
dc_mailname_in_oh='true'
dc_localdelivery='mail_spool'
" > /etc/update-exim4.conf.conf
    echo "Done."
    echo "Restarting Exim4..."
    /etc/init.d/exim4 restart
    echo "Done."
fi
