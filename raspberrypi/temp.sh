#!/bin/bash

if whoami != "root" ; then
    echo "Need root."
    exit
fi

version="2012-12-27 19.53"

clear
tput cup 1 35
printf "Hardware Info"
tput cup 2 0
printf "Version $version"
tput cup 3 0
printf "Press any key to exit."
tput cup 5 0
printf "Initial temperature was"
tput cup 5 24
temperature=""
while [ -z "$temperature" ]
   do
      temperature="$(cat /sys/class/thermal/thermal_zone0/temp)"
   done
temperature="$(($temperature/1000*1))"
printf "$temperature"
tput cup 5 27
printf "C"
tput cup 5 30
printf "Throttle at: "$(($(cat /sys/class/thermal/thermal_zone0/trip_point_0_temp)/1000))"C"
tput cup 6 0
printf "Current temperature is"

# put keyboard in non-blocking mode
if [ -t 0 ]; then
  stty -echo -icanon time 0 min 0
fi


tput cup 10 0
printf "CPU governor: "`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`

keypressed=""
while [ "x$keypressed" = "x" ]
   do
      tput cup 6 24
      temperature=""
      while [ -z "$temperature" ]
         do
            temperature="$(cat /sys/class/thermal/thermal_zone0/temp)"
         done
      temperature="$(($temperature/1000*1))"
      echo "$temperature C"
      tput cup 6 26
      
      # CPU Freq
      cpufreqmin=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)
      cpufreqcur=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq)
      cpufreqmax=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
      
      tput cup 7 25
      printf "CPU frequencies"
      tput cup 8 0
      printf "Min"
      tput cup 8 10
      printf "/"
      tput cup 8 15
      printf "Current"
      tput cup 8 25
      printf "/"
      tput cup 8 30
      printf "Max"
      
      tput cup 9 0
      printf $(($cpufreqmin/1000))" MHz "
      tput cup 9 10
      printf "/"
      tput cup 9 15
      printf $(($cpufreqcur/1000))" MHz "
      tput cup 9 25
      printf "/"
      tput cup 9 30
      printf $(($cpufreqmax/1000))" MHz "
      
      tput cup 11 0
      printf "CPU Usage:"
      tput cup 11 11
      printf $(eval $(awk '/^cpu /{print "previdle=" $5 "; prevtotal=" $2+$3+$4+$5 }' /proc/stat); sleep 0.4; eval $(awk '/^cpu /{print "idle=" $5 "; total=" $2+$3+$4+$5 }' /proc/stat); intervaltotal=$((total-${prevtotal:-0})); echo "$((100*( (intervaltotal) - ($idle-${previdle:-0}) ) / (intervaltotal) ))")"%%  "
      
      sleep 1
      read keypressed
   done

# Restore standard input default mode
if [ -t 0 ]; then 
    stty sane
fi

clear
echo "Exiting. Please wait..."
clear
exit 0

