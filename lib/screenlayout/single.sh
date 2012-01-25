#!/bin/sh
#winpos save
exit
xrandr -d :0 --output DP3 --off --output DP2 --off --output DP1 --off --output TV1 --off --output HDMI2 --off --output HDMI1 --off --output LVDS1 --mode 1280x800 --pos 0x0 --rotate normal --output VGA1 --off
#xrandr -d :0 --output DP3 --off --output DP2 --off --output DP1 --off --output TV1 --off --output HDMI2 --off --output HDMI1 --off --output LVDS1 --off --output VGA1 --off
#while wmctrl -d|grep -vq '1280x';do sleep 1;done;
#xfce4-panel --restart

