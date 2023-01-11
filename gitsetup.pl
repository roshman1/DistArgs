#!/usr/bin/perl

# Read an .git/config file, make sure it has the following entries in the appropriate 
# sections.

$fields = {
	 'filter "rcs-keywords"'	=> {
	 	'clean' => '.git_filters/rcs-keywords.clean',
	 	'smudge' => '.git_filters/rcs-keywords.smudge %f',
	 }
};

my $sec = '';
my $secnames = {};
my $field = undef;
my $curval = "";

while(<>) {
	/^\s*\[([^\]]+)\]/ && do {
		$newsec = $1;
		checksec($sec);
		$sec = $newsec;
		print;
		next;
	};
	/^\s*([^\s=]+)\s*([=:])\s*(.*)/ && do {
		$newname = $1; $newval = $3;
		$newval =~ s/\s+$//;
		$secnames->{$sec}{$newname} = $newval;
		if ($fields->{$sec}{$1} && ($fields->{$sec}{$1} ne $newval)) {
			print $newname . $2 . $fields->{$sec}{$1} . "\n";
		} else {
			print;
		}
		next;
	};
	print;
}

checksec($sec);

foreach $sec (keys %{$fields}) {
	if (!$secnames->{$sec}) {
		print "\n[$sec]\n";
		foreach $name (keys %{$fields->{$sec}}) {
			print "\t$name = ".$fields->{$sec}{$name}."\n";
		}
	}
}


sub checksec {
	my ($sec) = @_;
	
	if ($fields->{$sec}) {
		my $flag = 0;
		foreach $name (keys %{$fields->{$sec}}) {
			if (!defined($secnames->{$sec}{$name})) {
				print "\t$name = ".$fields->{$sec}{$name}."\n";	
				$flag = 1;
			}
		}
		print "\n" if $flag;
	}
}
	
