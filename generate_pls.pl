#!/usr/bin/perl -w

use strict;

$|=1;

use lib '/home/slava/opt/lib/perl5/';
use Common qw(find_files echo);
use RND;


my $rnd_list = RND->new(2, Common::find_files('/work/Music/', '*.mp3'));
my $count = $ARGV[0] || $rnd_list->list_size();

for (my $i = 1 ; $i <= $count; $i++) {
	Common::echo( $rnd_list->get_rnd_item());
}

