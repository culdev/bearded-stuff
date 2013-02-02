#!/bin/bash

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

    
    # Display usage
    *)
    echo -e "Usage: $(basename $0) OPTION...

help                        Displays this text.
bridge {CTID}               Removes eth0 and bridges eth0 and eth1 with host.
burstmemory {CTID} {GM} {BM}
                            Adds burst memory to CTID.
                             GM = Guaranteed memory
                             BM = Burst memory"
    ;;
esac

exit 0
