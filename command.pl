#!/usr/bin/perl -w

use strict;

$|=1;

if (fork() == 0) {
	exec(join(' ', @ARGV));
}