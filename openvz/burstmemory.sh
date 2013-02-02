#!/bin/bash
ct=$1
guarmem=$2
burstmem=$3

if [ "$ct" == "" ] || [ "$guarmem" == "" ] || [ "$burstmem" == "" ]; then
    echo -e "Missing parameters, 1 = container id, 2 = guaranteed memory, 3 = burst memory.\nE.g $0 100 256M 512M\nContainer id 100 will receive 256MB guaranteed memory and 512MB burstable."
    exit
fi
 
vzctl set $ct --vmguarpages $guarmem --save
vzctl set $ct --oomguarpages unlimited --save
vzctl set $ct --privvmpages $burstmem --save
vzctl set $ct --physpages unlimited --save