#!/bin/bash
CMD=audtool2
pidof audacious2 || exec audacious2 --play

if audtool2 current-song-filename|grep -qv '^http';then 
	audtool2 playback-playpause;
	exit
fi

if $CMD playback-playing; then 
  $CMD playback-stop
else 
  $CMD playback-play
fi
