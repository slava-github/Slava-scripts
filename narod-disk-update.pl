#!/usr/bin/perl -w

use HTTP::Request;
use LWP::UserAgent;
$| = 1;
srand(time());

my $list = "
http://narod.ru/disk/25381487000/Kitaro-lossless.part8.rar.html
http://narod.ru/disk/25381211000/Kitaro-lossless.part7.rar.html
http://narod.ru/disk/25374101000/Kitaro-lossless.part6.rar.html
http://narod.ru/disk/25364104000/Kitaro-lossless.part5.rar.html
http://narod.ru/disk/25360396000/Kitaro-lossless.part4.rar.html
http://narod.ru/disk/25359623000/Kitaro-lossless.part3.rar.html
http://narod.ru/disk/24391129000/Kitaro-lossless.part2.rar.html
http://narod.ru/disk/24390944000/Kitaro-lossless.part1.rar.html
http://narod.ru/disk/23832850000/Queen-320.rar.html
http://narod.ru/disk/861981000/8-harvatia07_1.avi.html
http://narod.ru/disk/861982000/9-harvatia07_1.avi.html
http://narod.ru/disk/861743000/6-harvatia07_1.avi.html
http://narod.ru/disk/861744000/7-harvatia07_1.avi.html
http://narod.ru/disk/861422000/4-harvatia07_1.avi.html
http://narod.ru/disk/861423000/5-harvatia07_1.avi.html
http://narod.ru/disk/863121000/6-harvatia07_2.avi.html
http://narod.ru/disk/863032000/5-harvatia07_2.avi.html
http://narod.ru/disk/862899000/4-harvatia07_2.avi.html
http://narod.ru/disk/862698000/3-harvatia07_2.avi.html
http://narod.ru/disk/862543000/2-harvatia07_2.avi.html
http://narod.ru/disk/862361000/1-harvatia07_2.avi.html
http://narod.ru/disk/862193000/10-harvatia07_1.avi.html
http://narod.ru/disk/862194000/11-harvatia07_1.avi.html
http://narod.ru/disk/861241000/3-harvatia07_1.avi.html
http://narod.ru/disk/861091000/2-harvatia07_1.avi.html
http://narod.ru/disk/861002000/1-harvatia07_1.avi.html
http://narod.ru/disk/13745862000/Cap0328(0022).avi.html
http://narod.ru/disk/13745827000/Cap0328(0021).avi.html
http://narod.ru/disk/13745681000/Cap0328(0020).avi.html
http://narod.ru/disk/13745647000/Cap0328(0019).avi.html
http://narod.ru/disk/13745414000/Cap0328(0018).avi.html
http://narod.ru/disk/13745305000/Cap0328(0017).avi.html
http://narod.ru/disk/13745288000/Cap0328(0016).avi.html
http://narod.ru/disk/13745147000/Cap0328(0015).avi.html
http://narod.ru/disk/13745115000/Cap0328(0014).avi.html
http://narod.ru/disk/13745087000/Cap0328(0013).avi.html
http://narod.ru/disk/13744889000/Cap0328(0012).avi.html
http://narod.ru/disk/13744802000/Cap0328(0011).avi.html
http://narod.ru/disk/13744790000/Cap0328(0010).avi.html
http://narod.ru/disk/13744739000/Cap0328(0009).avi.html
http://narod.ru/disk/13744716000/Cap0328(0008).avi.html
http://narod.ru/disk/13744672000/Cap0328(0007).avi.html
http://narod.ru/disk/13744656000/Cap0328(0006).avi.html
http://narod.ru/disk/13744648000/Cap0328(0005).avi.html
http://narod.ru/disk/13744170000/Cap0328(0004).avi.html
http://narod.ru/disk/13744076000/Cap0328(0003).avi.html
http://narod.ru/disk/13744031000/Cap0328(0002).avi.html
http://narod.ru/disk/13743963000/Cap0328(0001).avi.html
http://narod.ru/disk/13743853000/Cap0328.avi.html
";
my @list =  split("\n", $list);
shift @list;
while (@list) {
	my @newlist;
	my $i = 0;
	foreach my $fname (@list) {
		$i++;
		$fname =~ s#disk/#disk/intget/# unless $fname =~ m#/intget/#;
		print "$i) ".$fname."\n";
		open (FL, "wget -o /dev/null --user-agent='Mozilla/5.0 (Windows; U; Windows NT 5.2; en-US; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1 YB/3.5.1' '$fname' -O - |");
#		open (FL, "wget -o /dev/null --user-agent='Mozilla/5.0 (Windows; U; Windows NT 5.2; en-US; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1 YB/3.5.1' '$fname' -O - |grep 'rel=\"yandex_bar\"'|");
#		if(my ($host, $page) = <FL> =~ m#rel="yandex_bar" href="/disk/start/([^/]+)/([^"]+)"#){
#			sleep(int(rand(5)));
#			print my $s = "http://$host/disk/$page";
		if (my $s = <FL>) {
			print $s;
			my $req = HTTP::Request->new("GET", $s);
			$req->header("Range"=>"bytes=-".(int(rand(1000))+1));
			my $ua = LWP::UserAgent->new(timeout => 10, parse_head => 0);
			my $res = $ua->request($req);
			if ($res->is_success) {
				print " get ".length($res->content())." bytes";
			} else {
				print "Connect ERROR";
				push @newlist, $fname;
			}
			print "\n";
		} else {
			print "Banned";
			push @newlist, $fname;
		}
		close(FL);
		print "\nsleep ".(my $rnd = int(rand(30))+1);
		sleep ($rnd);
		print "\n";
	}
	@list = @newlist;
	if (@list) {
		my $time = 10+int(rand(10));
		print "Wait $time min before next try....\n";
		sleep($time*60);
	}
}
