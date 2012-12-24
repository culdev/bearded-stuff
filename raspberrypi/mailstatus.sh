#!/bin/bash
TMP=/tmp/status
MAIL="some@mail.com"
SUBJECT="Pi Status"

echo "<html><head></head><body><p>" > $TMP

# Get cpu information
cpucurfreq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq)
cpuminfreq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)
cpumaxfreq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
cpugovernor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
cputemp=$(cat /sys/class/thermal/thermal_zone0/temp)
cputempthrottle=$(cat /sys/class/thermal/thermal_zone0/trip_point_0_temp)
cpuusage=$(eval $(awk '/^cpu /{print "previdle=" $5 "; prevtotal=" $2+$3+$4+$5 }' /proc/stat); sleep 0.4; eval $(awk '/^cpu /{print "idle=" $5 "; total=" $2+$3+$4+$5 }' /proc/stat); intervaltotal=$((total-${prevtotal:-0})); echo "$((100*( (intervaltotal) - ($idle-${previdle:-0}) ) / (intervaltotal) ))")"%"
uptime=$(uptime)

echo "<b>Information:</b><pre>
CPU governor:		  $cpugovernor
CPU frequency cur:	  $(($cpucurfreq/1000)) MHz
CPU frequency min:	  $(($cpuminfreq/1000)) MHz
CPU frequency max:	  $(($cpumaxfreq/1000)) MHz
CPU temperature:	  $(($cputemp/1000))C
CPU throttle temperature: $(($cputempthrottle/1000))C
CPU usage:		  $cpuusage
Uptime:			 $uptime
</pre>" >> $TMP

# Latest processes
echo "<br><b>Ten latest cpu intensive processes:</b><br><pre>" >> $TMP
top -b -n 1 | head -n 17 | tail -n 11 >> $TMP
echo "</pre>" >> $TMP

# Disk stats
echo "<br><b>Disk stats:</b><br><pre>" >> $TMP
df -h >> $TMP
echo "</pre>" >> $TMP

# syslog
echo "<br><b>Latest ten lines from syslog:</b><br><pre>" >> $TMP
tail -n 10 /var/log/syslog >> $TMP
echo "</pre>" >> $TMP

# auth.log
echo "<br><b>Latest ten lines from auth.log:</b><br><pre>" >> $TMP
tail -n 10 /var/log/auth.log >> $TMP
echo "</pre>" >> $TMP

# user.log
echo "<br><b>Latest ten lines from user.log:</b><br><pre>" >> $TMP
tail -n 10 /var/log/user.log >> $TMP
echo "</pre>" >> $TMP

# update-checker log
echo "<br><b>Update-checker from user.log:</b><br><pre>" >> $TMP
cat /var/log/user.log | grep "update-checker" | tail -n 30 >> $TMP
echo "</pre>" >> $TMP

# /proc/meminfo
echo "<br><b>Proc meminfo:</b><br><pre>" >> $TMP
cat /proc/meminfo >> $TMP
echo "</pre>" >> $TMP

# Close html
echo "</p></body></html>" >> $TMP

# Mail it!
mutt -n -e "set copy=no" -e "set content_type=text/html" $MAIL -s "$SUBJECT" < $TMP

rm $TMP