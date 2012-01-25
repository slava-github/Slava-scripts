#!/bin/bash

xrl=/tmp/xrandr.last

function waitWM {
	data=$1;
#	while wmctrl -d|grep -vq "$data";do sleep 1;done;
	for (( i=1 ; $i<10 ; i++ )) ; do
		if wmctrl -d|grep "$data";then
			i=100
		else 
			sleep 1
		fi;
	done;
	if [ "$i" == "10" ];then
		wmctrl -d
	fi
}

function saExit {
	xrandr -q >$xrl
	exit
}

(
FILE=/tmp/winpos.slava
set -e
echo -en "\n\nStart "
date
set -o xtrace
c=`cat $xrl || true`
n=`xrandr -q`
if [ "$c" = "$n" ] && ( [ -z "$1" ] || [ "$1" != "force" ] );then exit;fi

winpos save stdout >$FILE.tmp
if ( [ -n "$2" ] && [ "$2" = "single" ] && (xrandr -q|grep -q 'LVDS1 connected') ) || ( (xrandr -q|grep -c ' connected'|grep -q 1) && (xrandr -q|grep -q 'LVDS1 connected') );then
	test -e $FILE || mv $FILE.tmp $FILE
	xrandr --output HDMI2 --off 
	waitWM "1280x999"
	xrandr --output DP3 --off --output DP2 --off --output DP1 --off --output TV1 --off --output HDMI2 --off --output HDMI1 --off --output LVDS1 --mode 1280x800 --pos 0x0 --rotate normal --output VGA1 --off
	waitWM "1280x800"
	xfce4-panel --restart
	sleep 3
	wmctrl -c Gigolo
	saExit
elif xrandr -q|grep -Ec 'HDMI(1|2) connected'|grep -q 2;then
	xrandr --output DP3 --off --output DP2 --off --output DP1 --off --output TV1 --off --output HDMI2 --off --output HDMI1 --mode 1280x1024 --pos 0x0 --rotate normal --output LVDS1 --off --output VGA1 --off
	waitWM "1280x999"
	xrandr --output DP3 --off --output DP2 --off --output DP1 --off --output TV1 --off --output HDMI2 --mode 1280x1024 --pos 1280x0 --rotate normal --output HDMI1 --mode 1280x1024 --pos 0x0 --rotate normal --output LVDS1 --off --output VGA1 --off
	waitWM "2560x999"
	xfce4-panel --restart
	test -e $FILE || saExit
	winpos restore stdin < $FILE
	mkdir -p /tmp/slava.bkp
	mv $FILE /tmp/slava.bkp/winpos.`date +%Y%m%d-%H%M%S`
	wmctrl -c Gigolo
	saExit
fi
test -e $FILE || mv $FILE.tmp $FILE
) >>/home/slava/.local/log/mon-chng.log 2>&1

