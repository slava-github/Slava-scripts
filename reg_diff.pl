#!/usr/bin/perl -w

use strict;

$|=1;

my $f1 = read_file($ARGV[0]);
my $f2 = read_file($ARGV[1]);
diff($f1, $f2);

sub read_file {
	my $fname = shift;
	open(FH, "<$fname");
	my %data;
	my $dir_key;
	while (my $line = <FH>) {
		chomp($line);
		next if $line eq '';
		if (!($line =~ m/\[([^\]]+)\]/) && ($dir_key)) {
			my ($name, $val) = split('=', $line, 2);
			$data{$dir_key}->{$name} = $val if defined $val && $val;
		} else {
			$dir_key = $1 if $1;
		}
	}
	return \%data;
}

sub diff {
	my ($f1, $f2) = @_;
	foreach my $key (sort keys %{$f2}) {
		my $res = '';
		my $val = $f2->{$key};
		if ( exists $f1->{$key}) {
			foreach my $key_f1 (sort keys %{$f1->{$key}}) {
				unless ( exists ($val->{$key_f1})) {
					$res .= "- $key_f1=$f1->{$key}->{$key_f1}\n";
				} elsif ($f1->{$key}->{$key_f1} ne $val->{$key_f1}) {
					$res .= "- $key_f1=$f1->{$key}->{$key_f1}\n";
					$res .= "+ $key_f1=$val->{$key_f1}\n";
				}
				delete $val->{$key_f1};
			}
			$res .= echo_hash($val, '+')
		} else {
			$res .= echo_hash($val, '+');
		}
		if ($res) {
			print "[$key]\r\n$res\r\n";
		}
	}
}

sub echo_hash {
	my ($hash, $sign) = @_;
	my $res = '';
	while(my ($key, $val) = each(%{$hash})){
		$res .= "$sign $key=$val\n";		
	}
	return $res;
}
