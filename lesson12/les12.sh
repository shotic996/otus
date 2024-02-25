#!/bin/bash
set -eu
clk_tck=`getconf CLK_TCK`

(
echo "PID|TTY|STAT|TIME|COMMAND";
for pid in /proc/[0-9]*/stat; do
        stat=`<$pid`
        cmd=`echo "$stat" | awk -F" " '{print $2}'`
        state=`echo "$stat" | awk -F" " '{print $3}'`
        tty=`echo "$stat" | awk -F" " '{print $7}'`
        utime=`echo "$stat" | awk -F" " '{print $14}'`
        stime=`echo "$stat" | awk -F" " '{print $15}'`
        ttime=$((utime + stime))
        time=$((ttime / clk_tck))

        echo "${pid}|${tty}|${state}|${time}|${cmd}"
done
) | column -t -s "|"
