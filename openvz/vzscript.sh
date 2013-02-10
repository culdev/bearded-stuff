#!/bin/bash

BASENAME=$(basename $0)

# $1 = Variable to check for content
isSet()
{
    if [ ! "$1" ] || [ "$1" == "" ]; then
        return 1
    else
        return 0
    fi
}

case "$1" in
    # Bridge network
    bridge)
        if ! isSet "$2"; then
            echo "Requires container id."
            exit 1
        fi
        
        vzctl set $2 --netif_del eth0 --save
        vzctl set $2 --netif_del eth1 --save
        vzctl set $2 --netif_add eth0,,,,vzbr0 --save
        vzctl set $2 --netif_add eth1,,,,vzbr1 --save
        
        echo "Done."
    ;;
    
    # Burst memory
    burstmemory)
        ct=$2
        guarmem=$3
        burstmem=$4

        if [ "$ct" == "" ] || [ "$guarmem" == "" ] || [ "$burstmem" == "" ]; then
            echo -e "Missing parameters, 2 = container id, 3 = guaranteed memory, 4 = burst memory.\nE.g $0 -bm 100 256M 512M\nContainer id 100 will receive 256MB guaranteed memory and 512MB burstable."
            exit 1
        fi
         
        vzctl set $ct --vmguarpages $guarmem --save
        vzctl set $ct --oomguarpages unlimited --save
        vzctl set $ct --privvmpages $burstmem --save
        vzctl set $ct --physpages unlimited --save
    ;;
    
    # Initiate container
    initiate)
        ctid=$2
        eth1ip=$3
        
        if ! isSet "$ctid" || ! isSet "$eth1ip"; then
            echo "Missing parameters.
Usage: $BASENAME {CTID} {eth1 IP}
Example: $BASENAME 100 23
Initiates container id 100 with eth1 ip 10.10.1.23"
            exit 1
        fi
        
        vzctl stop $ctid
        vzctl umount $ctid
        $0 bridge $ctid
        vzctl start $ctid
        
        # Regenerate ssh keys
        if [ "$(vzctl exec $ctid "dpkg --get-selections | grep openssh-server" | wc -l)" != "0" ]; then
            vzctl exec $ctid rm -f /etc/ssh/ssh_host_*_key*
            vzctl exec $ctid dpkg-reconfigure openssh-server
        fi
        
        # Debian
        if vzctl exec $ctid "cat /etc/debian_version" > /dev/null; then
            # Setup eth1
            vzctl exec $ctid "echo \"auto eth1
iface eth1 inet static
    address 10.10.1.$eth1ip
    netmask 255.255.255.0
    gateway 10.10.1.1
    metric 10\" >> /etc/network/interfaces"
        else
            echo "Only debian is supported for now."
        fi
        
        vzctl restart $ctid
        
        echo "Initiated container $ctid."
    ;;

    
    # Display usage
    *)
    echo -e "Usage: $BASENAME OPTION...

help                        Displays this text.
bridge {CTID}               Removes eth0 and bridges eth0 and eth1 with host.
burstmemory {CTID} {GM} {BM}
                            Adds burst memory to CTID.
                             GM = Guaranteed memory
                             BM = Burst memory
initiate {CTID} {eth1 IP}   Bridges network connections, adds eth1 on Debian
                             and regenerates ssh keys."
    ;;
esac

exit 0
