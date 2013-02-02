#!/bin/bash

if [ "$1" == "" ]; then
    echo "You need to specify container id."
    exit;
fi

vzctl set $1 --netif_del eth0 --save
vzctl set $1 --netif_del eth1 --save
vzctl set $1 --netif_add eth0,,,,vzbr0 --save
vzctl set $1 --netif_add eth1,,,,vzbr1 --save
