#!/usr/bin/perl -w

use strict;

$|=1;

use POSIX;

my $USAGE = "Usage: $0 [restore] [profile]";
my $pfName = '/tmp/slava.prof';
my %profiles = (
	'work' => ['HDMI1', 'HDMI2'],
);
my %monSort = (
	'VGA1' => 200,
);
exit;
plog(strftime( "%c", localtime(time)));
`winpos save stdout >/tmp/winpos-new.slava`;
my $curData = getData(1);
my $newData = getData();
my $restore = (defined $ARGV[0] && $ARGV[0] eq 'restore')?'restore':'';
#exit if (!$restore && $curData->{src} eq $newData->{src});
plog($curData->{src});
my $pos;
my $prof;
if (defined $ARGV[1]) {
	open(FH, '>'.$pfName);
	print FH $ARGV[1];
	close FH;
}
if (open(FH, '<'.$pfName) && ($prof = <FH>) && checkProfile($newData, $prof)) {
	$newData->{Monitor} = allOff($newData->{Monitor}, $profiles{$prof});
}
autoSwitch({'Monitor' => allOff($newData->{Monitor})});
`xrandr -q`;
$pos = autoSwitch($newData, $restore);
`while wmctrl -d|grep -vq "$pos""x";do sleep 1;done`;
`xfce4-panel --restart`;

exit;

sub checkProfile {
	my ($data, $prof) = @_;
	chomp $prof;
	return 0 unless defined $profiles{$prof};
	my $mon = $data->{Monitor};
	for(@{$profiles{$prof}}) {
		return 0 if (!$mon->{$_} || $mon->{$_}->{state} ne 'connected');
	}
	return 1;
}

sub profSwitch {
	my ($data, $prof) = @_;
}

sub allOff {
	my ($monitor, $exc) = @_;
	my %hash;
	if (ref $exc eq 'ARRAY') {
		$hash{$_} = 1 for(@{$exc});
	}
	my %new;
	while (my ($key, $val) = each(%{$monitor})) {
		unless (exists $hash{$key}) {
			$new{$key}->{state} = 'disconnected';
			$new{$key}->{'sort'} = $val->{'sort'};
		} else {
			$new{$key} = $val;
		}
	}
	return \%new;
}

sub autoSwitch {
	my ($newData, $restore) = @_;
	my @on;
	my $cmd = '';
	for (sort {$newData->{Monitor}->{$a}->{'sort'} <=> $newData->{Monitor}->{$b}->{'sort'}} keys %{$newData->{Monitor}}) {
#	while (my ($name, $data) = each (%{$newData->{Monitor}})) {
		my ($name, $data) = ($_, $newData->{Monitor}->{$_});
		if ($data->{state} eq 'disconnected') {
			$cmd .= ' --output '.$name.' --off';
			next;
		}
		if (exists ($data->{cur})) {
			$data->{cur}{freq} =~ s/[*+]//;
			unshift @on, [$name, $data->{cur}{res}, $data->{cur}{freq}];
			next;
		}
		push @on, [$name, $data->{recom}{res}, $data->{recom}{freq}];
	}

	my $pos;
	if ($on[0]) {
		$cmd .= sprintf(' --output %s --mode %s --rate %s --pos 0x0',@{$on[0]}) if $on[0];
		($pos) = $on[0]->[1] =~ m/^(\d+)/;
	}
	my $winpos = $restore || 'save';
	my $pos1 = 0;
	if ($on[1]) {
		$cmd .= sprintf(' --output %s --mode %s --rate %s --pos %dx0',@{$on[1]}, $pos);
		$winpos = 'restore';
		($pos1) = $on[1]->[1] =~ /^(\d+)/;	
	}
	$pos += $pos1;
	plog($winpos);
	if ($winpos eq 'save') {
		my $bkpName = 'winpos.'.strftime('%Y%m%d-%H%M', localtime(time()));
		`mkdir -p /tmp/winpos.bkp;mv /tmp/winpos.slava /tmp/winpos.bkp/$bkpName`;
		`mv /tmp/winpos-new.slava /tmp/winpos.slava`;
	} else {
		`winpos restore stdin < /tmp/winpos.slava`;
	}
	plog($cmd);
	`xrandr $cmd`;
	return $pos;
}

sub plog {
	my ($name) = $0 =~ m|([^/]+)\.[^.]+$|;
	open (LOG, ">> /home/slava/.local/log/$name.log");
	print LOG join(" ", map {(defined $_)?$_:''} @_)."\n";
}

sub getData {
	my $current = shift;
	$current = ($current)?'--current':'';
	my $s = `xrandr -q $current`;
	my @data = split("\n", $s);
	my %result = (src => $s, 'monitors' => 0);
	my $monitor = '';
	my $i = 1;
	while (my $str = shift @data) {
		if ($str =~ /^Screen (\d+)/) {
			$result{Screen}->{$1} = $str;
		} elsif ($str =~ /^(\S+) (\S+) (\S+)/) {
			$monitor = $1;
			$result{Monitor}->{$1}->{state} = $2;
			$result{Monitor}->{$1}->{'sort'} = $monSort{$1} || $i++;
			if ($2 eq 'connected') {
				$result{Monitor}->{$1}->{geometry} = $3;
				$result{monitors}++;
			}
		} elsif ($str =~ /^\s+(\S+)\s+(.+)/ && $monitor) {
			my $res = $1;
			my $sf = $2;
			$sf =~ s/ \+/\+/;
			my @freq = split(/\s+/, $sf);
			for (my $i = 0;$i<$#freq;$i++){
				if ($freq[$i] =~ s/\*//) {
					$result{Monitor}->{$monitor}->{cur} = 
						{res => $res, freq => $freq[$i]}
				}
				if ($freq[$i] =~ s/\+//) {
					$result{Monitor}->{$monitor}->{recom} = 
						{res => $res, freq => $freq[$i]}
				}
			}
			push @{$result{Monitor}->{$monitor}->{resols}}, 
				{'type'=>$res, 'freqs' => \@freq};
		}
	}
	return \%result;
}

