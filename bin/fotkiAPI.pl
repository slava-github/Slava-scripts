#!/usr/bin/perl -w

package main;
use strict;

$| = 1;

use POSIX;
use File::Basename;
use Digest::MD5;

my $USER = 'vsn';
my $ALBUM_PASSWD = 'PfrhsnsqFkm,jv';
my $BASE_PATH = '/home/slava/fotki.API/albums/Photo';
#my $BASE_PATH = '/work/Foto';
my $CHARSET = 'koi8r';


my %commands = (
	'clearWeb' => sub{clearWeb($USER)},
	'uploadToWeb' => sub{uploadToWeb($BASE_PATH, $CHARSET, $USER, $ALBUM_PASSWD)},
	'getRandPhoto' => sub{getRandPhoto()},
	'calcMD5' => sub{},
	'albumsInfo' => sub{my @args = @_;albumsInfo($USER, @args)}
);

unless (@ARGV) {
	die "Usage: $0 [".join(' | ', keys %commands)."]\n";
}

my $command = shift @ARGV;
$commands{$command}->(@ARGV);

exit;

sub albumsInfo {
	my ($USER, $command, @args) = @_;
	my $coll = FotkiAPI::Collection->new(user => $USER);
	my $albums = $coll->getAlbums();
	if ($command eq 'count') {
		print scalar(@{$albums})."\n";
	} 
	elsif ($command eq 'full-info') {
		foreach my $album (@{$albums}) {
			print "Title: ".$album->title()."\n";
			print "Entry:\n";
			print $album->entry()."\n";
			print "------\n\n";
		}
	}
}

sub getRandPhoto {
	my $user = shift;
	my $collection = FotkiAPI::Collection->new(user => $user);
	my $photos = $collection->getPhotos();
}

sub clearWeb {
	my $user = shift;
	my $collection = FotkiAPI::Collection->new(user => $user);
	my $albums = $collection->getAlbums();
	for(@$albums) {
		printf("Delete Album %s\n", $_->title());
		$_->delete();		
	}
}

sub uploadToWeb {
	my ($basePath, $charset, $user, $albumPasswd) = @_;
	my $convert = FotkiAPI::Convert->new(charset => $charset);
	my $collection = FotkiAPI::Collection->new(user => $user);
	my $localList = getLocalList($basePath); 
	while ( my ($albumName, $files) = each(%$localList) ) {
		my $albumNameUtf = $convert->convert($albumName);
		my $album;
		unless ($album = $collection->albumByName($albumNameUtf)) {
			$album = $collection->createAlbum({title=>$albumNameUtf, password=>$ALBUM_PASSWD});
			print "Album $albumName created\n";
		}
		my $count = @$files;
		my $sended = 0;
		for (@$files) {
			my $fileNameUtf = $convert->convert(my $fileName = $_);
			unless ($album->getPhotoByName($fileNameUtf)) {
				print int(100*$sended/$count)."%\n";
				do {
					eval{$album->createPhoto("$basePath/$albumName/$fileName", $fileNameUtf)};
				} while ($@ && sleep 10);
			} else { print ".";}
			$sended++;
		}
	}
}

sub getLocalList {
	my ($basePath) = @_;

	my %list;
	open(DH, "find $basePath -type f -iname '*.jpg' -or -iname '*.tiff'|") or die 'Can`t load list of local albums';
	while (<DH>) {
		chomp;
		my ($name, $path) = fileparse($_);
		$path =~ s|^\Q$basePath\E/||;
		$path =~ s|/$||;
		push @{$list{$path}}, $name;
	}
	return \%list;
}


sub testCollection {
	my $coll = FotkiAPI::Collection->new(user => $USER);
	my $albums = $coll->getAlbums();
	print "Count Albums: ".scalar @{$albums}."\n";

	my $album = $coll->createAlbum({title=>'Test1_'.time(), password=>$ALBUM_PASSWD});
	print "Created album: ".$album->title()."\n";
	$album->modify('title' => ['DATA', 'Test_Rename '.$album->title()]);
	print "Renamed album to ".$album->title()."\n";
	my $photo = $album->createPhoto('/home/slava/fotki.API/DSCN0180.JPG');
	print "Created photo: ".$photo->title()."\n";
	$photo->delete();
	$album->delete();
	print "Delete All $photo $album\n";
}

sub TestConvert {
	my $str = 'Тест';
	my $conv = FotkiAPI::Convert->new(charset => $CHARSET);
	print $str = $conv->convert($str)."\n";
	print $str = $conv->convert($str)."\n";
}

1;

#-------------------------------------------
package FotkiAPI::Object;

use strict;

sub new {
	my $class = shift;
	die "Incoming Attribut in class $class only hash" if (scalar @_ &&  @_ % 2);
	my %attr = (@_);
	my $self = bless {}, $class;
	$self->_init(\%attr);
	return $self;
}

sub _init {
	my ($self, $attr) = @_;
}

sub _setProp {
	my ($self, $attr, $name) = @_;
	ref($attr) eq 'HASH'  && (defined $attr->{$name}) or die "Property $name not defined";
	$self->{"_".$name} = $attr->{$name};
}


1;

#-------------------------------------------
package FotkiAPI::Convert;

use base qw(FotkiAPI::Object);

use Text::Iconv;

sub _init {
	my ($self, $attr) = @_;
	
	$self->SUPER::_init($attr);
	$self->_setProp($attr, 'charset');

	$self->{_toUtf8} = Text::Iconv->new($self->{_charset}, 'utf8');
	$self->{_fromUtf8} = Text::Iconv->new('utf8', $self->{_charset}.'//TRANSLIT')
}

sub convert {
	my ($self, $str) = @_;
	$str = $self->{_toUtf8}->convert($str) unless ($self->{_fromUtf8}->convert($str));
	return $str;
}

sub convertDir {
	my ($self, $str) = @_;
	return join('/', map{$self->convert($_)} (split('/', $str)));
}

1;

#-------------------------------------------
package FotkiAPI::Utils;

sub searchData {
	my ($data, $name, $rule) = @_;
	$rule ||= '';
	my ($pref, $rdata) = $data =~ m#<(?:[^:]+\:)?\Q$name\E([^>]*\Q$rule\E[^>]*)(?:>(.*?)</(?:[^:]+\:)?\Q$name\E>| />)#s;
	my %res;
	if ($pref) {
		my ($name, $val, $quote);
		while (
			(
				$pref =~ s/^\s*([^=]+)=(['"])//
				&& ($name = $1)
				&& ($quote = $2)
			) 
			&& (
				$pref =~ s/^([^$quote]*)$quote//
			)
 		) {
			$res{$name} = $1;
		}
	}
	$res{DATA} = $rdata if $rdata;
	return (scalar keys %res)?\%res:undef; 
}

sub doRules {
	my ($data, $rules) = @_;
	my %info;
	scalar keys %{$rules};
	while (my ($name, $rule) = each(%{$rules})) {
		if (ref($rule) eq 'HASH' && scalar(keys %{$rule}) > 0) {
			scalar keys %{$rule};
			while (my ($newname, $rule) = each(%{$rule})) {
				if (my $info = searchData($data, $name, $rule)) {
					$info{$newname} = $info;
				}
			}
		} else {
			if (my $info = searchData($data, $name, $rule)) {
				$info{$name} = $info;
			}
		}
	}
	return \%info;
}

sub splitEntrys {
	my $data = shift;
	my @entrys;
	while ($data =~ s#(<entry[^>]*>.+?</entry>)##s) {
		push @entrys, $1;
	};
	return \@entrys;
}


#-------------------------------------------

package FotkiAPI::Request;

use base qw(FotkiAPI::Object);

use HTTP::Request;
use LWP::UserAgent;

use constant CFG_PATH => '/home/slava/.fotkiAPI';

my %tokenHash;

sub _init {
	my ($self, $attr) = @_;
	$self->{userAgent} = $attr->{userAgent} || UserAgent();
	$self->_setProp($attr, 'user'); 
}

sub clone {
	my $self = shift;
	return FotkiAPI::Request->new(user=>$self->{_user});
}

sub Auth {
	my ($self, $method, $uri) = @_;
	my $req = HTTP::Request->new($method, $uri);
	$req->header('Authorization' => sprintf('FimpToken realm="fotki.yandex.ru", token="%s"', $self->token()));
	return $req;
}

sub doRequest {
	my ($self, $req) = @_;
	my $res = $self->{userAgent}->request($req);
	$res->is_success() or die "ERROR\n".$res->status_line."\n".$res->content;
	return $res->content() if $res->content();
}

sub Get {
	my ($self, $url) = @_;
	return $self->doRequest($self->Auth("GET", $url));
}

sub _Send {
	my ($self, $method, $url, $content) = @_;
	my $req = $self->Auth($method, $url);
	$req->content_type("application/atom+xml; charset=utf-8; type=entry");
	$req->content($content);
	return $self->doRequest($req);
}

sub Post {
	my $self = shift;
	$self->_Send('POST', @_);
}

sub Put {
	my $self = shift;
	$self->_Send('PUT', @_);
}

sub token {
	my $self = shift;

	return $tokenHash{$self->{_user}} if exists $tokenHash{$self->{_user}};

	my $file_token = CFG_PATH."/".$self->{_user}.".token";
	my $token = '';
	if ( -f $file_token ){
		open(FH, "<$file_token");
		$token = <FH>;
		chomp $token;
	} else {
		$token = $self->_genToken();
		mkdir CFG_PATH;
		open(FH, ">$file_token");
		print FH $token;
		close(FH);
	}
	$tokenHash{$self->{_user}} = $token;
	return $token;
}

sub _genToken {
	my $self = shift;

	my $req = HTTP::Request->new("GET", 'http://auth.mobile.yandex.ru/yamrsa/key/');
	my $res = $self->{userAgent}->request($req);
	my %hres;
	if ($res->is_success) {
		foreach my $key (qw/key request_id/) {
			$hres{$key} = $1 if ($res->content() =~ m#<$key>([^<]+)</$key>#);
		}
	} else {
		die "Connect ERROR\n".$res->content();
	}
	my $passwd = GetPasswd($self->{_user});
	my $credentials = YaEncrypt(sprintf('<credentials login="%s" password="%s"/>', $self->{_user}, $passwd), $hres{key});

	$req = HTTP::Request->new("POST",  'http://auth.mobile.yandex.ru/yamrsa/token/');
	$req->content_type('application/x-www-form-urlencoded');
	$req->content(sprintf('request_id=%s&credentials=%s', $hres{request_id}, $credentials));
	sleep 1;
	$res = $self->{userAgent}->request($req);
	if ($res->is_success) {
		return $1 if ($res->content() =~ m#<token>([^<]+)</token>#);
	} else {
		die "Error getting token\n".$res->content();
	}
}

sub GetPasswd {
	my $name = shift;
	print "Get password for user $name: ";
	my $res = `bash -c 'read -s pswd;echo \$pswd'`;
	chomp($res);
	return $res;
}

sub YaEncrypt {
	my ($str, $key) = @_;
	my $res = `ya-encrypt '$key' '$str'`;
	chomp $res;
	return $res;
}


sub UserAgent {
	my %attr = @_;
	defined $attr{timeout} or $attr{timeout} = 10; 
	defined $attr{parse_head} or $attr{parse_head} = 0;
	return LWP::UserAgent->new(%attr);
}

1;
#-------------------------------------------

package FotkiAPI::Collection;

use base qw(FotkiAPI::Object);

use constant HOST => 'http://api-fotki.yandex.ru';


sub _init {
	my ($self, $attr) = @_;
	$self->_setProp($attr, 'user');
	$self->{_request} = FotkiAPI::Request->new(user => $self->{_user});

	$self->{uri} = HOST."/api/users/$self->{_user}/";
	$self->{_base_doc} = $self->{_request}->Get($self->{uri});
	my $res = FotkiAPI::Utils::doRules(
		$self->{_base_doc},
		{
			'collection' => {
				'albums_uri' => 'id="album-list"',
				'photos_uri' => 'id="photo-list"',
			}	
		}
	);
	$self->{"_albumsUri"} = $res->{'albums_uri'}->{href};
	$self->{"_photosUri"} = $res->{'photos_uri'}->{href};
	$self->reset();
}

sub reset {
	my $self = shift;
	$self->{albumsList} = undef;
	$self->{albumsHash} = undef;
}

sub getAlbums {
	my $self = shift;

	unless ($self->{albumsList}) {
		$self->{albumsList} = [];
		foreach my $album (@{FotkiAPI::Utils::splitEntrys($self->{_request}->Get($self->{_albumsUri}))}) {
			push @{$self->{albumsList}}, $self->albumByEntry($album);
		};
	}
	return $self->{albumsList};
}

sub createAlbum {
	my ($self, $data) = @_;
	my $content = sprintf('<entry xmlns="http://www.w3.org/2005/Atom" xmlns:f="yandex:fotki">'
  		.'<title>%s</title><summary>%s</summary><f:password>%s</f:password></entry>'
		,$data->{title} || '', $data->{summary} || '', $data->{password} || ''
	);
	my $res = $self->{_request}->Post(($data->{album})?$data->{album}->uri():$self->{_albumsUri}, $content);
	my $album = $self->albumByEntry($res);
	push @{$self->{albumsList}}, $album if ($self->{albumsList});
	$self->{albumsHash}->{$album->title()} = $album if ($self->{albumsHash});
}

sub albumByEntry {
	my ($self, $entry) = @_;
	return FotkiAPI::Album->new(entry=>$entry, request=>$self->{_request});
}

sub albumByName {
	my ($self, $name) = @_;
	unless ($self->{albumsHash}) {
		my $albums = $self->getAlbums();
		for (@$albums) {
			$self->{albumsHash}->{$_->title()} = $_;
		}
	}
	return $self->{albumsHash}->{$name} if (exists $self->{albumsHash}->{$name});
	return ;
}

1;
#-------------------------------------------

package FotkiAPI::Entry;

use base qw(FotkiAPI::Object);

sub _init {
	my ($self, $attr) = @_;
	$self->_setProp($attr, 'entry');
	$self->_setProp($attr, 'request');
	$self->reset();
}

sub reset {
	my $self = shift;
	$self->{_prop} = undef;	
}

sub _rules {
	my $self = shift;
	return {
		title => '',
		id => ''
	}
}

sub entry {
	my $self = shift;
	return $self->{_entry};
}

sub _parseProp {
	my $self = shift;
	$self->{_prop} = FotkiAPI::Utils::doRules($self->{_entry}, $self->_rules());
}

sub prop {
	my $self = shift;
	$self->_parseProp() unless ($self->{_prop});
	return $self->{_prop};
}

sub title {
	my $self = shift;
	return $self->prop()->{title}->{DATA};
}

sub id {
	my $self = shift;
	return $self->prop()->{id}->{DATA};
}

sub modify {
	my $self = shift;
	$self->_readEntry();
	while ( my ($name, $data) = %{@_}) {	
		$self->_modifProp($name , @{$data});
	}
	$self->_commit();
}

sub _readEntry {
	my $self = shift;
	$self->{_entry} = $self->{_request}->Get($self->prop()->{editUri}->{href});
	$self->reset();
}

sub _modifProp {
	my ($self, $name, $prop, $value) = @_;
	
	$self->prop()->{$name}->{$prop} = $value;
	my $rules = $self->_rules();
	my $realName = '';
	my $rule = '';
	while (($realName, my $hrule) = each(%{$rules})) {
		last if (!$hrule && $realName eq $name);
		if (ref($hrule) eq 'HASH' && exists($hrule->{$name})) {
			$rule = $hrule->{$name};
			last;
		}
	}
	my ($start, $end) = ('', ' />');
	while (my ($key, $val) = each(%{$self->prop()->{$name}})) {
		if ($key eq 'DATA') {
			$end = ">$val</$name>";
		} else {
			$start .= " $key=\"$val\"";
		}
	}
	$self->{_entry} =~ s#<(?:[^:]+\:)?\Q$realName\E([^>]*\Q$rule\E[^>]*)(?:>(.*?)</(?:[^:]+\:)?\Q$name\E>| />)#<$realName$start$end#s;
}

sub _commit {
	my $self = shift;
	$self->{_entry} = $self->{_request}->Put($self->prop()->{editUri}->{href}, $self->{_entry});
	$self->reset();
}

sub delete {
	my $self = shift;
	$self->{_request}->doRequest($self->{_request}->Auth('DELETE', $self->prop()->{editUri}->{href}));
}

1;
#-------------------------------------------

package FotkiAPI::Album;

use base qw(FotkiAPI::Entry);

use POSIX;
use File::Basename;
use Digest::MD5;

sub reset {
	my $self = shift;
	$self->{_photos} = undef;
	$self->{_photosHash} = undef;
	$self->SUPER::reset();
}

sub _rules {
	my $self = shift;
	return {
		%{$self->SUPER::_rules()},
		'image-count' => '',
		'link' => {
			'uri' => 'rel="self"',
			'editUri' => 'rel="edit"',
			'photosUri' => 'rel="photos"',
			'webUri' => 'rel="alternate"'
		}
	};
}

sub uri {
	my $self = shift;
	return $self->prop()->{uri}->{href};
}

sub photosUri {
	my $self = shift;
	return $self->prop()->{photosUri}->{href};
}

sub photos {
	my $self = shift;
	
	my $uri = $self->photosUri();
	$self->{_photos} = [];
	while ($uri) {
		my $data = $self->{_request}->Get($uri);
		$data =~ s#(.+?)(<entry>)#$2#s or last;
		my $shead = $1;
		my $head = FotkiAPI::Utils::doRules (
			$shead,
			{
				'link' => 'rel="next"'
			}
		);
		$uri = $head->{link}->{href};
		foreach my $photo (@{FotkiAPI::Utils::splitEntrys($data)}) {
			push @{$self->{_photos}}, FotkiAPI::Photo->new(entry=>$photo, request=>$self->{_request});
		};
	}
	return $self->{_photos};
}

sub getPhotoByName {
	my ($self, $name) = @_;
	unless ($self->{_photosHash}) {
		my $photos = $self->photos();
		for(@$photos) {
			$self->{_photosHash}->{$_->title()} = $_;
		}
	}
	return $self->{_photosHash}->{$name} if (exists $self->{_photosHash}->{$name});
	return ;
}

sub _putRequest {
	my $self = shift;
	unless (defined $self->{_putRequest}) {
		$self->{_putRequest} = $self->{_request}->clone();
		$self->{_putRequest}->{userAgent}->timeout(60*10);
	}
	return $self->{_putRequest};
}

sub createPhoto {
	my ($self, $file, $title) = @_;
	if ((my $size = (stat($file))[7]) && open(FH, "<$file")) { 
		my $content;
		binmode(FH);
		my $time = time();
		print strftime('%d/%m/%Y %H:%M:%S', localtime($time))." file $file size $size Read";
		my $rsize = read(FH, $content, $size);
		die "Can't read all file (read $rsize of $size)" if $rsize != $size;
		my $md5 = Digest::MD5::md5_base64($content);

		my $req = $self->_putRequest()->Auth("POST", $self->photosUri());
		$req->content_type("image/jpeg");
		$req->content_length($size);
		my ($filename) = $file =~ m#[/\\](.+?)$#;
		$req->header('Slug', $filename);
		$req->content($content);
	
		print " Send";
		my $photo = FotkiAPI::Photo->new(entry=>$self->_putRequest()->doRequest($req), request=>$self->{_request}, md5_id=>$md5);
		print " speed - ".int($size / (time()-$time))." byte/sec\n";
		$photo->modify(
			'title' =>  ['DATA', $title || basename($file)], 
			'f:access' => ['value', 'publick'],
		);
		return $photo;
	}
}

1;
#-------------------------------------------

package FotkiAPI::Photo;

use base qw(FotkiAPI::Entry);

sub _rules {
	my $self = shift;
	return {
		%{$self->SUPER::_rules()},
		'f:access' => '',
		'f:disable_comments' => '',
		'content' => '',
		'link' => {
			'editUri' => 'rel="edit"',
			'albumUri' => 'rel="album"',
		}
	}
};

sub modify {
	my $self = shift;
	my $h = \@_;
	if (exists($h->{title}) && exists($self->{md5_id})) {
		$h->{title}->[1] .= " [ID:".$self->{md5_id}."]";
	}
	$self->SUPER::modify(@_);
};


sub _parseProp {
	my $self = shift;
	$self->SUPER::_parseProp();
	my $title = $self->{_prop};
	$title = s/ \[ID:(\w+)\]//;
	$self->{_title} = $title;
	$self->{md5_id} = $1 if $1;
}

sub title {
	my $self = shift;
	return $self->{_title};
}

1;
