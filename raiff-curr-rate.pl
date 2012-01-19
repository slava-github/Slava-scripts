#!/usr/bin/perl -w

use strict;

$| = 1;

use LWP::UserAgent;
use HTTP::Request;
use POSIX;

my $file = '/home/slava/.local/log/curr-rate.log';

my $time = strftime('"%d/%m/%Y %H:%M"', localtime(time()));
my $ua = LWP::UserAgent->new(timeout=>10, parse_head=>0);
my $req = HTTP::Request->new('GET', 'http://connect.raiffeisen.ru/rba/show-rates.do');
my $res = $ua->request($req);
$res->is_success() or die "ERROR\n".$res->status_line."\n".$res->content;
my $cont = $res->content();



#       rates[0]=new RateBean('USD', '', '31.2500', '31.5700', '', '', '1');
#       rates[1]=new RateBean('EUR', '', '44.6900', '45.1400', '', '', '1');
my $data = '';
foreach my $curr ('EUR', 'USD') {
	if (my ($sell, $buy) = $cont =~ m/RateBean\('$curr', '', '([\d.]+)', '([\d.]+)'/) {
		$data .= sprintf(',"%.2f","%.2f"', $buy, $sell);
	}
}
$data =~ tr/./,/;
print "DATA:'".$data."'\n";
exit unless $data;

my $olddata = `test -f $file && tail -n 1 $file`;
my @ar = split('",', $olddata);
$olddata = ','.join('",', $ar[2], $ar[3], $ar[5], $ar[6]);
print "OLDDATA:'".$olddata."'\n";

exit if ($olddata && $olddata =~ m/\Q$data\E/);

$req = HTTP::Request->new('GET', 'http://pda.micex.ru/');
$res = $ua->request($req);
$res->is_success() or die "ERROR\n".$res->status_line."\n".$res->content;
$cont = $res->content();

my @mmvb;
foreach my $curr ('EUR', 'USD') {
	my ($n) = $cont =~ m#\Q$curr\ERUB_TOM.+?<td class="nobr black">[^<]+?([\d\,]+)#s;
	push @mmvb, $n;
}
$data = ",\"$mmvb[0]\"$data";
$data =~ s/((.+?,){6})/$1"$mmvb[1]",/;

open(FH, ">>$file");
print FH $time.$data."\n";

