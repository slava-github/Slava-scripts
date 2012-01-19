#!/usr/bin/perl -w
use strict;

#print10();
#exit;

my @data;
foreach (0..10000) {
	$data[int(rnd()*10)]++;
}
foreach (@data) {
	print ''.((defined $_)?$_:0)."\n";
}
exit;

sub print10 {
	for (my $i=0; $i<10;$i++){
		print rnd()."\n"
	}
}

sub rnd {
	open(RND, '/dev/urandom');
	binmode(RND);
	my $s = '0.';
	read(RND, $s,4);
	my $int = unpack('L', $s);
	return '0.'.$int;
	my $c;
	foreach (1..10) {
		read(RND, $c, 1);
		$s .= ord($c);
	}
	close(RND);
	return $s;
}
