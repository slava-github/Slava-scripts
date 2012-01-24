#!/usr/bin/perl -w

use strict;

$|=1;

my ($file_name, $split_size, $flat) = @ARGV;
@ARGV or die "$0 <file name> <split size> <flat>\n";

my $cmd  = ($flat)?'cat':'gzip -c';

$split_size = ExtractSize($split_size);
if($file_name !~ m#^\.{0,2}/#) {
	$file_name ='./'.$file_name;
}
open(FH, "<".$file_name);
binmode(FH);

my $buff;
my $read_bytes = 0;
my $count = 0;
my $file_count = 1;
my $wfh;
while(my $read = read(FH, $buff, 1024)) {
	$read_bytes += $read;
	if (++$count > 1024) {
		print ".";
		$count = 0;	
	}
	if ($read_bytes >= $split_size) {
		close($wfh);
		undef $wfh;
#		print "\nNext File Number: $file_count\nPress any key\n";
#		read(STDIN, my $c, 1);
		$read_bytes = 0;
	}
	unless ($wfh) {
		my $new_name = $file_name;
		$file_count = sprintf('%02d', $file_count);
		$new_name =~ s#/(.+)$#/$file_count-$1#;
		$new_name .= (($flat)?'':'.gz');
		open($wfh, "|$cmd > $new_name");
		binmode($wfh);
		$file_count++;
	}
	print $wfh $buff;	
}
print "\n";

sub ExtractSize {
	my $size = shift;
	my %mul = (
		'k' => 1024,
		'm' => 1024*1024
	);
	return ($size =~ /^(\d+)(K|M)$/i)? $1*$mul{lc($2)} : $size;
}
