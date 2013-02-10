#!/bin/bash

FROM="/var/lib/dhcp/"
TO="/var/lib/dhcp_persist/"

# -v, --verbose               increase verbosity
# -u, --update                skip files that are newer on the receiver
# -r, --recursive             recurse into directories
# --delete                    remove files from $TO if they do not exist in $FROM
rsync -vur --delete $FROM $TO
