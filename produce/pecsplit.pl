#!/usr/bin/perl
# TODO: this needs review by a Perl expert, I am a Perl newbie.

use strict;
use warnings;

# Setting the variable

sub path_prefix_map_enquote {
    my $part = shift;
    $part =~ s/%/%#/g;
    $part =~ s/=/%+/g;
    $part =~ s/:/%./g;
    return $part;
}

sub path_prefix_map_append($$$) {
    my $curmap = shift;
    my $dst = shift;
    my $src = shift;
    return (length($curmap) ? $curmap . ":" : "") .
        path_prefix_map_enquote($dst) . "=" . path_prefix_map_enquote($src);
}

$ENV{"BUILD_PATH_PREFIX_MAP"} = path_prefix_map_append(
    $ENV{"BUILD_PATH_PREFIX_MAP"}, $ENV{"NEWDST"}, $ENV{"NEWSRC"});

exec @ARGV;
