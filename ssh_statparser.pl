#!/usr/bin/perl -w

$| = 1;

while (1) {
	print STDERR 'Number of parser: ';
	my ($user, $server) = ('statbox');
	$server = readline(STDIN);
	if ($server =~ s/^slava@//) {
		$user = 'slava';
	}
	chomp($server);
	if ($server eq '64') {
		$server = 'statdev-64';
		$user = 'slava';
	} elsif ($server =~ /^w(\d)/) {
		$server = "stbx-webface0$1e";
	} elsif ($server =~ /^\d+$/ ) {
		$server = "parser$server"."d";
	} elsif ($server =~ /^m(\d+)$/) {
		$server = "smr-parser$1"."e";	
	} elsif ($server =~ /^b(\d+)$/) {
		$server = "betaparser$1";	
	}
	
	if ($server) {
		print "$user\@$server\n";
		system("ssh $user\@$server");
		system("clear");
	} else {
		exit;
	}
}
