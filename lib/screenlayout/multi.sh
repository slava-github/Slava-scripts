#!/bin/sh
xrandr --output LVDS1 --mode 1280x800 --pos 0x0 --rotate normal --output HDMI1 --mode 1280x1024 --pos 1280x0 --rotate normal
while wmctrl -d|grep -vq '2560x';do sleep 1;done;
xfce4-panel --restart
sleep 3
winpos restore
