package RND;

sub new {
	my ($class, $iter, $list) = @_;
	my $self = {
		iter => $iter || 10,
		list => $list,
	};	
	srand(time^$$);
	$self = bless $self;
	return $self;
}

sub get {
	my ($self, $num) = @_;
	my $res;
	for (my $i=1; $i<$self->{iter};$i++) {
		my $rnd = rand($num);
		if ((!defined $res) || (abs($self->{prev} - $rnd) > abs($self->{prev} - $res))) {
			$res = $rnd;
		}
		last unless (defined $self->{prev});
	}
	$self->{prev} = $res;
	return $res;	
}

sub get_item {
	my ($self, $rnd_flag) = @_;
	my $size = $self->list_size();
	return 0 unless ($size);
	my $num_item = ($rnd_flag) ? int($self->get($size-1)) : 0;
	my $result = $self->{list}->[$num_item];
	my $ender = pop @{$self->{list}};
	if ($size > 1) {
		$self->{list}->[$num_item] = $ender;
	}
	return $result;
}

sub get_rnd_item {
	my $self = shift;
	return $self->get_item(1);
}

sub list_size {
	my $self = shift;
	return scalar(@{$self->{list}});
}

1;