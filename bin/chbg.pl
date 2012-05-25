#!/usr/bin/perl -w

use strict;
use POSIX;
use Fcntl ':flock';
use IO::Handle;

$| = 1;

my @interval = (60*10, 60*60*2);
#~ my @interval = (2, 10);
my $path = '/work/Foto/';

f_change() if ($ARGV[0] && $ARGV[0] eq '-change');

run_lock();

$SIG{USR1} = sub{sleep 1};

FileList::Init();
srand();

while (1) {
	if (stat($path)) {
		create_file(get_file_name($path));
		reset_desktop();
		FileList::Log('Sleep: ', my $int = int(rand($interval[1] - $interval[0])+$interval[0]));
		sleep $int;
	} else {
		sleep 10;
	}
}

sub run_lock {
	my $file_name = '/var/tmp/chbg.pid';
	my $lock = 0;
	if (!open(FLR, "<$file_name") || (flock(FLR, LOCK_EX | LOCK_NB) && ($lock = 1))) {
		our $flwh;
		if (open($flwh, ">$file_name") && ($lock || flock($flwh, LOCK_EX | LOCK_NB))) {
			print $flwh $$;
			flush $flwh;
			return 1;
		}
		close($flwh);
		print "qq";
	}
	exit 1;
}

sub get_file_list {
	return [split("\n", `find $path -iname '*.jpg' -not -path '*/Source/*'`)];
}

sub get_file_name {
	my $path = shift;
	my $list = get_file_list();
	my $count = scalar(@{$list});
	my $num = 0;
	while ($count) {
		$count--;
		$num = int(rand($count));
		if (FileList::Find($list->[$num])) {
			if ($count) {
				my $tmp = $list->[$num];
				$list->[$num] = $list->[$count];
				$list->[$count] = $tmp;
				print ".";
			} else {
				FileList::Reset();
				$list = get_file_list();
				$count = scalar(@{$list});
				print "*";
			}
		} else {
			last;
		}
	}
	print "-";
	return $list->[$num];
}

sub create_file {
	my $file_name = shift;
	my $cmd;
	if (-f '/usr/bin/convert') {
		my $file = FileList::GetPath()."/wallpaper.jpg";
		$cmd = "rm $file;convert '$file_name' -auto-orient -resize 1280x1280 ".$file;
	} else {
		$cmd = "ln -sf '$file_name' ".FileList::GetPath()."/wallpaper.jpg";
	}
	system($cmd);
}

sub reset_desktop {
	while (system('xfdesktop --reload')) {
		system('xfdesktop &');
		sleep 1;
	}
}

sub f_change {
	my $r = `kill -10 \`cat /var/tmp/chbg.pid\`;sleep 3;tail -n 2 /home/slava/.wallpaper/show.log|grep -c 'Sleep:'`;
	print $r;
}

1;

package FileList;

use strict;
use POSIX;

my $PATH;
my $LIST_NAME;
my $PREF;
my %list;

sub Init {
	$PATH= "/home/slava/.wallpaper";
	$LIST_NAME = "show.log";
	$PREF = "Show:";
	unless (open(LOG, "<$PATH/$LIST_NAME")) {
		system( "mkdir -p $PATH");
		return 0;
	};
	while (<LOG>) {
		if (m#\Q$PREF\E [\d/]+ [\d:]+ ([^\n]+)\n#) {
			$list{$1} = '1';
		}
	}
	print scalar(keys(%list))."\n";
}

sub Find {
	my $file_name = shift;
	unless (exists($list{$file_name})) {
		$list{$file_name} = 1;
		Log($PREF, strftime("%d/%m/%Y %H:%M:%S ", localtime()).$file_name);
		return 0;
	}
	return 1;
}

sub Log {
	my ($pref, $line) = @_;
	`echo '$pref $line' >> $PATH/$LIST_NAME`;
}

sub Reset {
	%list = ();
	unlink("$PATH/$LIST_NAME");
}

sub GetPath {
	return $PATH;
}



1;
