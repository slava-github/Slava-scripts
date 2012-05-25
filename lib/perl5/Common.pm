package Common;

use strict;

sub find_files {
	my ($path, $pattern, $options) = @_;
	my @result; 
	$options = '-type f' unless defined $options;
	echo(my $cmd = "find $path $options -name '$pattern'");
	open(FL, "$cmd|") or die 'Can\'t start finde mp3 files';
	while (<FL>) {
		chomp;
		push @result, $_;
	}
	return \@result;
}


sub echo {
	print join(' ', @_)."\n";
}

sub command {
	my ($cmd) = @_;
	my $fh;
	open($fh, "$cmd|") or die "Can't start command \"$cmd\"";
	return $fh;
}

1;