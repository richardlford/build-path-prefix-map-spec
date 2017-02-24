#!/usr/bin/perl

use strict;

# Setting the variable

sub pfmap_enquote {
	my $part = shift;
	$part =~ s/%/%#/g;
	$part =~ s/=/%+/g;
	$part =~ s/:/%./g;
	return $part;
	}

$ENV{"BUILD_PATH_PREFIX_MAP"} = sprintf("%s:%s=%s",
	$ENV{"BUILD_PATH_PREFIX_MAP"},
	pfmap_enquote($ENV{"NEWSRC"}),
	pfmap_enquote($ENV{"NEWDST"}));

exec @ARGV;
