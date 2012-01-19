#!/usr/bin/perl

use strict;
use warnings;

$| = 1;

open(FH, "LANG=C find -iname '*.jpg'|");
while(my $file = <FH>) {
	chomp($file);
	if ($file =~ m#(.+/)[^/]+(_\d+.jpg)# && index(lc($file), 'img_') < 0) {
		print $file."\n";
		rename($file, $1."img$2");
	}	
}
