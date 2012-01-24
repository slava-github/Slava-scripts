#!/usr/bin/perl -w

use strict;

$|=1;

my $USAGES = "Usages: $0 <file>|ALL\n   $0 restore <file>|All";
my $file_name = $ARGV[0] or die $USAGES;

my $ROOT = '/home/slava/.slava/global_data';

my $action = \&save;
if ($file_name eq 'restore') {
	$file_name = $ARGV[1] or die $USAGES;
	if ((lc($file_name) ne 'all') && (abs_path("./") !~ m/^\Q$ROOT\E/)) {
		die "for restoring path must be $ROOT";
	}
	$action = \&restore;
}

my $file_list;
if (lc($file_name) eq 'all') {
	$file_list = get_full_list();
} else {
	$file_list = [abs_path($file_name)];
}

foreach my $file (@{$file_list}) {
	&{$action}($file);
}

exit;

sub abs_path {
	my $file_name = shift;
	if ($file_name !~ m#^/#) {
		my $path = `pwd`;
		chomp($path);
		$file_name = $path."/$file_name";
	}
	return $file_name;
}

sub get_full_list {
	my @file_list;
	open(DIR, "find $ROOT -type f|");
	while (<DIR>) {
		chomp;
		s#^\Q$ROOT\E##;
		push @file_list, $_;
	}
	return \@file_list;
}

sub save {
	my $file_name = shift;
	my ($path, $name) = $file_name =~ m#^(.+?)/([^/]+)$#;
	foreach my $cmd ("mkdir -p $ROOT/$path", "cp -vp $file_name $ROOT$path") {
		print `$cmd`;
	}	
}

sub restore {
	my $file_name = shift;
	my ($path, $name) = $file_name =~ m#^\Q$ROOT\E(.+?)/([^/]+)$#;
	foreach my $cmd ("mkdir -p $path", "cp -vp $file_name $path") {
		print `$cmd`;
	}	
}