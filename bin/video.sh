#!/bin/bash
~/.screenlayout/vga.sh
#xrandr --output DP3 --off --output DP2 --off --output DP1 --off --output TV1 --off --output HDMI2 --off --output HDMI1 --off --output LVDS1 --mode 1280x800 --pos 0x0 --rotate normal --output VGA1 --mode 720x400 --pos 1280x0 --rotate normal
#xrandr --output DP3 --off --output DP2 --off --output DP1 --off --output TV1 --off --output HDMI2 --off --output HDMI1 --off --output LVDS1 --mode 1280x800 --pos 0x0 --rotate normal --output VGA1 --mode 1360x768 --pos 1280x0 --rotate normal
xrandr --output DP3 --off --output DP2 --off --output DP1 --off --output TV1 --off --output HDMI2 --off --output HDMI1 --off --output LVDS1 --mode 1280x800 --pos 0x0 --rotate normal --output VGA1 --mode 1320x768 --pos 1280x0 --rotate normal
save=$(amixer sget Master|tail -n 1|sed 's/.\+\[\([0-9]\+%\).\+/\1/')
amixer sset Master 100%
xset s off -dpms
#totem
#smplayer
vlc
xset s on +dpms
amixer sset Master $save
xrandr --output DP3 --off --output DP2 --off --output DP1 --off --output TV1 --off --output HDMI2 --off --output HDMI1 --off --output LVDS1 --mode 1280x800 --pos 0x0 --rotate normal --output VGA1 --off
zenity --info --text="Отключите телевизор"
xrandr -q
