#!/bin/bash
ct=$1
guarmem=$2
burstmem=$3

if [ "$ct" == "" ] || [ "$guarmem" == "" ] || [ "$burstmem" == "" ]; then
    echo -e "Missing parameters, 1 = container id, 2 = guaranteed memory, 3 = burst memory.\nE.g $0 100 256 512\nContainer id 100 will receive 256MB guaranteed memory and 512MB burstable."
    exit
fi

vzctl set $ct --vmguarpages $((256 * $guarmem)) --save
vzctl set $ct --oomguarpages unlimited --save
vzctl set $ct --privvmpages $((256 * $burstmem)) --save
vzctl set $ct --physpages unlimited --save
