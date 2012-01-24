#!/usr/bin/perl -w

package Speed;

sub new {
	my $self = bless {};
	$self->{time_prev} = time();
	$self->{buf} = [];
	$self->{aspeed} = 0;
	$self->{win} = $_[1];
	return $self;
}

sub calc {
	my ($self, $data) = @_;
	$time = time();
	$speed = 0;
	if (defined $self->{prev}) {
		$speed = ($data-$self->{prev})/($time-$self->{time_prev});
		$self->{aspeed} += $speed;
		push @{$self->{buf}}, $speed;
		if (@{$self->{buf}} > $self->{win}) {
			$self->{aspeed} -= shift @{$self->{buf}};
		}
	}
	$self->{prev} = $data;
	$self->{time_prev} = $time;
	return  [ ($speed/1024), $self->{aspeed}/(1024*(@{$self->{buf}}||1)) ];
}

1;

use strict;

$| = 1;

my $if = $ARGV[0];
my $sleep = $ARGV[1] || 1; 
my $win = $ARGV[2] || 10;
unless (defined $if) {
	#Получение активного интерфейса
	my $str = `netstat -i|grep eth|head -n 1`;
	$if = (split('\s+', $str))[0];
}
print "Active interface: $if\n";

my $crx = Speed->new($win);
my $ctx = Speed->new($win);
while(1) {
	my $str = `ifconfig $if|grep 'RX bytes'`;
	my ($rx, $tx) = $str =~ m#RX bytes:(\d+).+TX bytes:(\d+)#;
	$rx = $crx->calc($rx);
	$tx = $ctx->calc($tx);
	printf("Speed RX:%.3fK (%.3fK) TX:%.3fK (%.3fK) = TOTAL:%.3fK (%.3fK)\n", @$rx, @$tx, $rx->[0]+$tx->[0], $rx->[1]+$tx->[1]);
	sleep $sleep;
}

1;

