#!/bin/bash


if [ -e /tmpram/mumble/enable ]
then
	cp /tmpram/mumble/mumble-server.sqlite /var/lib/mumble-server/mumble-server.sqlite
fi