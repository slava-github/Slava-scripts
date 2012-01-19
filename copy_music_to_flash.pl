#!/usr/bin/perl -w

use strict;

$|=1;

use lib '/home/slava/.local/lib/perl5/';
use RND;
use Common;

my $Usage = "$0 <Dir Position> [Config name]\n";
defined (my $new_pos = $ARGV[0]) or die $Usage;

my $SOURCE_PATH = '/work/Music';
my $RESULT_PATH = '/media/MusicFlash/MP3';
my $MAX_FILE_NUMBER = 58;
my $MAX_DIR_NUMBER = 8;
my $ADD_BASE_NAME = 0;
my $MAX_SIZE;
my $RES_PLAY_LIST_NAME = "/list.pls";

init($ARGV[1]);

my $rnd = RND->new(2);
my $copier = FileCopier->new(
	max_file_number => $MAX_FILE_NUMBER, 
	max_dir_number => $MAX_DIR_NUMBER,
	path => $RESULT_PATH,
	add_base_name => $ADD_BASE_NAME,
);


main();

exit;

sub init {
	(my $conf_name = shift) or return;

	if (lc($conf_name) eq 'wito' || uc($conf_name) eq 'PDA') {
		$RESULT_PATH = '/media/disk/Mus_RND';
		$MAX_FILE_NUMBER = 50;
		$MAX_DIR_NUMBER = 8;
		$ADD_BASE_NAME = 1;
	} elsif (lc($conf_name) eq 'cd') {
		$SOURCE_PATH = '/work/Music/Song/';
		$RESULT_PATH = '/media/DISK/Mus_RND';
		$MAX_FILE_NUMBER = 80;
		$MAX_DIR_NUMBER = 4;
		$ADD_BASE_NAME = 1;
		$MAX_SIZE = 1400*1024;
	} elsif (lc($conf_name) eq 'test') {
		$RESULT_PATH = '/home/slava/tmp/MusTest';
		$MAX_FILE_NUMBER = 5;
		$MAX_DIR_NUMBER = 2;
		$ADD_BASE_NAME = 1;
#		$SOURCE_PATH = '/home/slava/tmp/MusSrc';
	}
}

sub main {

	my $cur_play_list = cur_play_list();

	my $full_list = find_files($SOURCE_PATH);

	unless (-f $cur_play_list) {
		new_drive($full_list);
	} else {
		my ($end_update, $ar_play_list, $h_play_list) = load_list($cur_play_list);
		delete($full_list->{$_}) foreach (@$ar_play_list);
		my @slist = keys %{$full_list};
		print 'Find files: '.scalar(@slist)."\n";
		
		if($new_pos <= $end_update) {
			clean_dirs($end_update+1);
			$copier->set_start_dir($end_update);
			my $list = copy(\@slist, 1);
			push @{$ar_play_list}, @{$list};
			$end_update = 0;
		}
		--$new_pos;
		
		clean_dirs($end_update+1, $new_pos);
		$copier->set_max_dir_number($new_pos);
		$copier->set_start_dir($end_update);
		my $list = copy(\@slist, 1);
		push @{$ar_play_list}, @{$list};
		
		save_list($ar_play_list, $cur_play_list);
	}
}

sub new_drive {
	my $full_list = shift;
	reset_drive($RESULT_PATH);
	my @slist = keys %{$full_list};
	my $result_list = copy(\@slist, 1);
	save_list($result_list, cur_play_list());	
}

sub cur_play_list {
	return "$RESULT_PATH/$RES_PLAY_LIST_NAME";
}

sub reset_drive {
	my $path = shift;
	Common::echo("reset $path");
	check_path($path);
	`rm -rf $path`;
	`mkdir -p $path`;
}

sub check_path {
	my $path = shift;
	die "Path $path is bad" if ($path =~ m#^(/|/home/[^/]+/?)$#);
}

sub clean_dirs {
	my ($start, $end) = @_;

	for (my $pos = $start ; 
			stat(my $path = $copier->subdir_name($pos)) && (!defined $end || $pos <= $end) ; 
			$pos++
	) {
		check_path($path);
		Common::echo("delete $path");
		`rm -rf $path`;
	}
}

sub copy {
	my ($full_list, $rnd_flag, $count) = @_;
	my (@result_list, $file_name);
	while (($file_name = get_item($full_list, $rnd_flag)) && $copier->can_copy($file_name)) {
		$copier->copy_file($file_name);
		push @result_list, $file_name;
		last if (defined $count && !(--$count));
	}
	return \@result_list;
}

sub load_list {
	my $file_name = shift @_;
	my (@ar_result, %h_result, $end_update);
	
	open(LST, "< $file_name");
	while (<LST>) {
		chomp;
		if (!$end_update && m/#-- (\d+)/) {
			$end_update = $1;
		} else {
			push @ar_result, $_;
			$h_result{$_} = 1;
		}
	}
	return ($end_update, \@ar_result, \%h_result);
}

sub save_list {
	my ($list, $file_name) = @_;
	unshift @{$list}, "#-- ".$copier->get_dir();
	open(LST, "> $file_name");
	foreach my $item (@{$list}) {
		print LST $item."\n";
	}
	`cp $file_name $copier->{backup_path}`;
}

sub get_item {
	my ($list, $rnd_flag) = @_;
	my $size = scalar @{$list};
	return 0 unless ($size);
	my $num_item = ($rnd_flag) ? int($rnd->get($size-1)) : 0;
	print " rnd=$num_item ";
	my $result = $list->[$num_item];
	my $ender = pop @{$list};
	if ($size > 1) {
		$list->[$num_item] = $ender;
	}
	return $result;
}

sub to_translit {
	my %koi2translit = (
		"Á" => "a", "Â" => "b", "×" => "v", "Ç" => "g", "Ä" => "d", "Å" => "e", "Ö" => "j", "Ú" => "z", "É" => "i", "Ê" => "iy", "Ë" => "k", "Ì" => "l", "Í" => "m", "Î" => "n", "Ï" => "o", "Ð" => "p", "Ò" => "r", "Ó" => "s", "Ô" => "t", "Õ" => "u", "Æ" => "f", "È" => "h", "Ã" => "c", "Þ" => "ch", "Û" => "sh", "Ý" => "sch", "Ø" => "'", "Ù" => "i", "ß" => "'", "Ü" => "ye", "À" => "yu", "Ñ" => "ya",
		"á" => "A", "â" => "B", "÷" => "V", "ç" => "G", "ä" => "D", "å" => "E", "ö" => "J", "ú" => "Z", "é" => "I", "ê" => "IY", "ë" => "K", "ì" => "L", "í" => "M", "î" => "N", "ï" => "O", "ð" => "P", "ò" => "R", "ó" => "S", "ô" => "T", "õ" => "U", "æ" => "F", "è" => "H", "ã" => "C", "þ" => "CH", "û" => "SH", "ý" => "SCH", "ø" => "'", "ù" => "I", "ÿ" => "'", "ü" => "YE", "à" => "YU", "ñ" => "YA"
	);
	my $name = shift;
	my @name = split('', $name);
	my $result;
	foreach my $chr (@name) {
		$result .= (exists($koi2translit{$chr}))? $koi2translit{$chr}: $chr;
	}
	return $result;
}

sub find_files {
	my ($path) = @_;
	my %result; 
	Common::echo(my $cmd = "find $path -type f -name '*.mp3' -or -name '*.MP3' -or -name '*.ogg'");
	open(FL, "$cmd|") or die 'Can\'t start finde mp3 files';
	while (<FL>) {
		chomp;
		$result{$_} = 1;
	}
	return \%result;
}


package FileCopier;

sub new {
	my $class = shift;
	my %inits = (@_);
	die "path undefined in FileCopier::new" unless $inits{path};
	die "MAX_FILE_NUMBER can only less 98" if (!defined $inits{max_file_number} || $inits{max_file_number} > 98);
	my $self = {
		max_file_number => $inits{max_file_number}, 
		max_dir_number => $inits{max_dir_number} || 10,
		start_dir_num => 0,
	};
	$self = bless $self;
	$self->set_path($inits{path});
	$self->reset();
	$self->{oper_start_time} = time()-1;
	$self->{oper_size} = 0;
	$self->{add_base_name} = $inits{add_base_name} || 0;
	
	return $self;
}

sub reset {
	my $self = shift;
	$self->{dir_count} = $self->{start_dir_num};
	$self->{count} = $self->{max_file_number};	
}

sub set_path {
	my ($self, $path) =@_;
	$self->{path} = $path;
	$path =~ s#/#_#g;
	$self->{backup_path} = "$ENV{HOME}/.flash_music/$path";
	`mkdir -p $self->{backup_path}`;
}

sub _create_marker {
	my $self = shift;
	my $WARN_FILE = '/home/slava/.local/usr/share/sounds/warning.wav';
	my $COUNT_FILE = '/home/slava/.local/usr/share/sounds/error.wav';
	my $CMD = 'lame --quiet -b64 -m m ';
	my $out_file = $self->_abs_path()."/01.mp3";
	`$CMD $WARN_FILE - >$out_file`;
	for (my $i = 1; $i<= $self->{dir_count}; $i++) {
		`$CMD $COUNT_FILE - >>$out_file`;
	}	
}

sub set_start_dir {
	my ($self, $dir_num) = @_;
	$self->{start_dir_num} =  $dir_num;
	$self->reset();
}

sub set_max_dir_number {
	my ($self, $dir_num) = @_;
	$self->{max_dir_number} = $dir_num;
}

sub subdir_name {
	my ($self, $dir) = @_;
	return sprintf("%s/%02d", $self->{path}, $dir);	
}

sub _abs_path {
	my $self = shift;
	return $self->subdir_name($self->{dir_count});
}

sub _quote_file_name {
	my $name = shift;
	$name =~ s/'/'\\''/g;
	return $name;
}

sub can_copy {
	my ($self, $file) = @_;
	my @stat = stat($file);
	my $free;
	if (defined $MAX_SIZE) {
		$free = $MAX_SIZE;
	} else {
		$free = `LANG=C df $self->{path}|grep -v 'Filesystem'`;
		($free) = $free =~ m#^[\S]+\s+\d+\s+\d+\s+(\d+)#;
	}
	if ( 
			$free*1024 > $stat[7]*1.5 &&
			!(
				$self->{count} >= $self->{max_file_number} 
				&& $self->{dir_count} >= $self->{max_dir_number} 
			)
	){
		$MAX_SIZE -= $stat[7]/1024 if defined $MAX_SIZE;
		return 1;
	} else {
		$self->_save_list();
		return 0;
	}
}

sub _save_list {
	my ($self) = @_;
	if ($self->{list} && scalar(@{$self->{list}})) {
		my $name = $self->{backup_path}.'/'.$self->{dir_count}.'.lst';
		open(FL, ">$name") or die "Can't open file $name";
		print FL join("\n", @{$self->{list}});
		close(FL);
	}
	$self->{list} = [];
}

sub _get_result_name {
	my ($self, $file_name) = @_;
	my $suffix = '.mp3';
	if (defined $file_name and $file_name) {
		$suffix = "_$file_name";
	}
	if (++$self->{count} > $self->{max_file_number}) {
		$self->_save_list();
		$self->{count} = 1;
		++$self->{dir_count};
		my $cmd = "mkdir -p ".$self->_abs_path();
		`$cmd`;
		$self->_create_marker();
	}
	return sprintf("%s/%02d%s", $self->_abs_path(), $self->{count}+1, $suffix);
}

sub copy_file {
	my ($self, $file) = @_;
	my ($basename) = $file =~ m#/([^/]+)$#;
	my $to_file = _quote_file_name($self->_get_result_name(($self->{add_base_name})?$basename:''));
	push @{$self->{list}}, $file;
	my $orig_file = $file;
	$file = _quote_file_name($file);
	print "$self->{dir_count}/$self->{count} '$basename'";
	my $cmd = "cp '$file' '$to_file'";
	`$cmd`;
	if ($?) {
		$self->{count}--;
		$to_file = _quote_file_name($self->_get_result_name(''));
		`cp '$file' '$to_file'`;
	}
	$self->print_speed($orig_file);
}

sub print_speed {
	my ($self, $filename, $time) = @_;
	$self->{oper_size} += (stat($filename))[7];
	my $res = $self->{oper_size}/(time() - $self->{oper_start_time});
	my $mes = "b/s";
	if ($res > 1024*1024) {
		$res = $res/(1024*1024);
		$mes = "Mb/s";
	}elsif ($res > 1024) {
		$res = $res/1024;
		$mes = "Kb/s";
	}
	printf(" (%.2f %s)\n", $res, $mes);
}

sub get_dir {
	my $self = shift;
	return $self->{dir_count};
}

1;
