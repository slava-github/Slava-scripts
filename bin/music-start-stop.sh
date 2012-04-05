#!/bin/bash
CMD=audtool
pidof audacious || exec audacious --play

if $CMD current-song-filename|grep -qv '^http';then 
	$CMD playback-playpause;
	exit
fi

if $CMD playback-playing; then 
  $CMD playback-stop
else 
  $CMD playback-play
fi
