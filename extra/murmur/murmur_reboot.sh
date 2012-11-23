#!/bin/bash

/etc/init.d/mumble-server stop

mkdir /tmpram/mumble
cp /var/lib/mumble-server/mumble-server.sqlite /tmpram/mumble/mumble-server.sqlite --preserve=timestamps
chown mumble-server:mumble-server /tmpram/mumble -R

/etc/init.d/mumble-server start

touch /tmpram/mumble/enable

