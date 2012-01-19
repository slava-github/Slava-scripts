#!/usr/bin/perl -w

use strict;
use POSIX;

$| = 1;

msg("Wait start Xserver");
sleep 1 while system('pgrep X >/dev/null');

my $opid = $$;
if (my $pid = fork()) {
	sleep 10;
	kill 9, $pid;
	msg('Time out');
	if (-f '/tmp/Xpatch.1') {
		msg('Reboot');
		system('/sbin/reboot');
	} elsif (-f '/tmp/Xpatch') {
		msg('Hibernate');
		system('touch /tmp/Xpatch.1');
		system('/usr/sbin/pm-hibernate');
	} else {
		msg('Suspend');
		system('touch /tmp/Xpatch');
		system('/usr/sbin/pm-suspend');
	}
} else {
	exec("su slava -c 'xrandr -d :0 -q' >/dev/null;kill -9 $opid");
}

sub msg {
	my $msg = shift;
	print strftime("%c $msg\n", localtime(time()));
}
