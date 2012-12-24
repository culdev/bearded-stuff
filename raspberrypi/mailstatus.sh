#!/bin/bash
TMP=/tmp/status
MAIL="some@mail.com"
SUBJECT="Pi Status"

echo "<html><head><style type=\"text/css\">
.theTitle {
    margin: 0 0 5px 0;
    font-weight: bold;
}
#wrap {
    margin: 0 0 10px 0;
}
#one {
    float:left;
    width: 20%;
    margin: 0 0 10px 0;
}
#two {
    float:right;
    width: 80%;
    margin: 0 0 10px 0;
}
</style></head><body>" > $TMP

# Get cpu information
cpucurfreq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq)
cpuminfreq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)
cpumaxfreq=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
cpugovernor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
cputemp=$(cat /sys/class/thermal/thermal_zone0/temp)
cputempthrottle=$(cat /sys/class/thermal/thermal_zone0/trip_point_0_temp)
cpuusage=$(eval $(awk '/^cpu /{print "previdle=" $5 "; prevtotal=" $2+$3+$4+$5 }' /proc/stat); sleep 0.4; eval $(awk '/^cpu /{print "idle=" $5 "; total=" $2+$3+$4+$5 }' /proc/stat); intervaltotal=$((total-${prevtotal:-0})); echo "$((100*( (intervaltotal) - ($idle-${previdle:-0}) ) / (intervaltotal) ))")"%"
uptime=$(uptime | sed -e "s/$(date '+%H:%M:%S')//g")

echo "<div id=\"wrap\">
    <p class=\"theTitle\">System Information:</p>
    <div id=\"one\">
        CPU governor:<br>
        CPU frequency current:<br>
        CPU frequency minimum:<br>
        CPU frequency maximum:<br>
        CPU temperature:<br>
        CPU throttle temperature:<br>
        CPU usage:<br>
        Uptime:<br>
        Hostname:<br>
        Debian version:<br>
        Kernel:<br>
    </div>
    <div id=\"two\">
        $cpugovernor<br>
        $(($cpucurfreq/1000)) MHz<br>
        $(($cpuminfreq/1000)) MHz<br>
        $(($cpumaxfreq/1000)) MHz<br>
        $(($cputemp/1000))C<br>
        $(($cputempthrottle/1000))C<br>
        $cpuusage<br>
        $uptime<br>
        $(hostname)<br>
        $(cat /etc/debian_version)<br>
        $(uname -a)<br>
    </div>
</div>" >> $TMP

# Memory info
echo "<p class=\"theTitle\">Memory information:</p><pre>" >> $TMP
free -m >> $TMP
echo "</pre>" >> $TMP

# Latest processes
echo "<p class=\"theTitle\">Ten latest cpu intensive processes:</p><pre>" >> $TMP
top -b -n 1 | head -n 17 | tail -n 11 >> $TMP
echo "</pre>" >> $TMP

# Disk stats
echo "<p class=\"theTitle\">Disk stats:</p><pre>" >> $TMP
df -h >> $TMP
echo "</pre>" >> $TMP

# iostat
echo "<p class=\"theTitle\">Iostat:</p><pre>" >> $TMP
iostat >> $TMP
echo "</pre>" >> $TMP

# w
echo "<p class=\"theTitle\">w:</p><pre>" >> $TMP
w >> $TMP
echo "</pre>" >> $TMP

# syslog
echo "<p class=\"theTitle\">Latest ten lines from syslog:</p><pre>" >> $TMP
tail -n 10 /var/log/syslog >> $TMP
echo "</pre>" >> $TMP

# auth.log
echo "<p class=\"theTitle\">Latest ten lines from auth.log:</p><pre>" >> $TMP
tail -n 10 /var/log/auth.log >> $TMP
echo "</pre>" >> $TMP

# user.log
echo "<p class=\"theTitle\">Latest ten lines from user.log:</p><pre>" >> $TMP
tail -n 10 /var/log/user.log >> $TMP
echo "</pre>" >> $TMP

# update-checker log
echo "<p class=\"theTitle\">Update-checker from user.log:</p><pre>" >> $TMP
cat /var/log/user.log | grep "update-checker" | tail -n 30 >> $TMP
echo "</pre>" >> $TMP

# /proc/meminfo
echo "<p class=\"theTitle\">Proc meminfo:</p><pre>" >> $TMP
cat /proc/meminfo >> $TMP
echo "</pre>" >> $TMP

# /proc/swaps
echo "<p class=\"theTitle\">Swaps:</p><pre>" >> $TMP
cat /proc/swaps >> $TMP
echo "</pre>" >> $TMP



# Close html
echo "</body></html>" >> $TMP

# Mail it!
mutt -n -e "set copy=no" -e "set content_type=text/html" $MAIL -s "$SUBJECT" < $TMP

rm $TMP
