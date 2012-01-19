#!/usr/bin/perl -w

use strict;

$|=1;

use lib '/home/slava/opt/lib/perl5/';
use Common;

die "Usage: $0 command remout_path\n" unless (scalar(@ARGV) == 2);
my ($command, $remout_path) = @ARGV;

my $file_list = generate_configs_list();
foreach my $file_name (@{$file_list}) {
	my $remout_file_name = $remout_path.'/'.$file_name;
	if (-e $remout_file_name) {
		print "$file_name\n";
		if ($command eq 'check' ) {
			print "$remout_file_name exists\n";
		} 
		elsif ($command eq 'diff') {
			my $diff_flags = '-bBi';
			my $cmd = sprintf("diff -q %s '%s' '%s'", $diff_flags, $file_name, $remout_file_name);
			my $result = `$cmd 2>&1`;
			Common::echo("'$result'");
			if ($? == 256 && ($result !~ m/^Binary/)) {
				my $cmd = sprintf("diff -u %s '%s' '%s'|less -S", $diff_flags, $file_name, $remout_file_name);
				system($cmd);
				Common::echo($?);
				print "Copy this file (Y/n)?";
				my $a = <STDIN>;
			}
		}
	}
}

exit 0;

sub generate_configs_list {
	my $file_list = Common::find_files('.', '.*', '-maxdepth 1 -type f');
	push @{$file_list}, '-----------';
	my $dir_list = Common::find_files('.', '.*', '-type d');
	foreach my $dir_name (@{$dir_list}) {
		push @{$file_list}, @{Common::find_files("$dir_name", '*')} if $dir_name ne '.';
	}
	return $file_list;
}