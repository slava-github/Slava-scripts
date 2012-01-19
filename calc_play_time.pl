#!/usr/bin/perl -w

use strict;

$|=1;

open(SHELL, '(while true; do sleep 1 ; echo stat;done)|xmms-shell|grep Time:|');
my $play_time = 0;
my $state_time = time();
my $play = 0;
while (<SHELL>) {
	print "DEBUG: ".$_;
	my $cur_state = $_ !~ 'paused';
	if ($cur_state != $play) {
		if ($play) {
			$play_time = time() - $state_time;
		}
		print $play_time."\n";
		$state_time = time();
	}
	$play = $cur_state;
}
