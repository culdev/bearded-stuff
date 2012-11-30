#!/bin/sh

# Settings
NETWORKADAPTER="eth1"
NETWORKSTATICIP="10.10.1.x"
NETWORKGATEWAY="10.10.1.1"
NETWORKNETMASK="255.255.255.0"

TMPRAM="/tmpram"

echo "Edit the script before running it."
exit 1

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

wget -O /tmp/dotdeb.gpg http://www.dotdeb.org/dotdeb.gpg
cat /tmp/dotdeb.gpg | apt-key add -
rm /tmp/dotdeb.gpg

echo "Installed dotdeb repository."

# Debian Backports
echo "Installing Debian Backports repository..."
echo "" >> $SOURCES
echo "# Debian Backports" >> $SOURCES
echo "deb http://backports.debian.org/debian-backports squeeze-backports main" >> $SOURCES
echo "Installed Debian Backports repository."

# mpt-statusd
# Floods various logs with "mpt-statusd: detected non-optimal RAID status"
echo "Disabling mpt-statusd..."
/etc/init.d/mpt-statusd stop
update-rc.d-insserv -f mpt-statusd remove
echo "Disabled mpt-statusd."

# /dev/shm
echo "Symlinking $TMPRAM to /dev/shm."
ln -s /dev/shm $TMPRAM

# crontab
echo "Installing crontab template"
echo "MAILTO=\"\"
SHELL=/bin/sh

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
