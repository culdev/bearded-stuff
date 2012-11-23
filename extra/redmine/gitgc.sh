#!/bin/bash

# settings
LOCKFILE="/dev/shm/gitgclock"
GITREPO="/home/redmine/reposgit"

# if LOCKFILE exists, exit
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "already running"
    exit
fi

# make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

for git in $GITREPO/*; do
   if [ -d $git ]; then
      cd $git
      git gc
   fi
done

rm -f ${LOCKFILE}
