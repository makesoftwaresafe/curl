#!/usr/bin/env perl
#***************************************************************************
#                                  _   _ ____  _
#  Project                     ___| | | |  _ \| |
#                             / __| | | | |_) | |
#                            | (__| |_| |  _ <| |___
#                             \___|\___/|_| \_\_____|
#
# Copyright (C) Daniel Stenberg, <daniel@haxx.se>, et al.
#
# This software is licensed as described in the file COPYING, which
# you should have received as part of this distribution. The terms
# are also available at https://curl.se/docs/copyright.html.
#
# You may opt to use, copy, modify, merge, publish, distribute and/or sell
# copies of the Software, and permit persons to whom the Software is
# furnished to do so, under the terms of the COPYING file.
#
# This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
# KIND, either express or implied.
#
# SPDX-License-Identifier: curl
#
###########################################################################
#
# This script grew out of help from Przemyslaw Iskra and Balint Szilakszi
# a late evening in the #curl IRC channel.
#

use strict;
use warnings;
use vars qw($Cpreprocessor);

#
# configurehelp perl module is generated by configure script
#
my $rc = eval {
    require configurehelp;
    configurehelp->import(qw(
        $Cpreprocessor
    ));
    1;
};
# Set default values if configure has not generated a configurehelp.pm file.
# This is the case with cmake.
if (!$rc) {
    $Cpreprocessor = 'cpp';
}

# we may get the dir root pointed out
my $root=$ARGV[0] || ".";

# need an include directory when building out-of-tree
my $i = ($ARGV[1]) ? "-I$ARGV[1] " : '';
my $error;


my @syms;
my %manpage;
my %symadded;

sub checkmanpage {
    my ($m) = @_;

    open(my $mh, "<", "$m");
    my $line = 1;
    my $title;
    my $addedin;
    while(<$mh>) {
        if(/^Title: (.*)/i) {
            $title = $1;
        }
        elsif(/^Added-in: (.*)/i) {
            $addedin = $1;
        }
        if($addedin && $title) {
            if($manpage{$title}) {
                print "$title is a duplicate symbol in file $m\n";
                $error++;
            }
            $manpage{$title} = $addedin;
            last;
        }
        $line++;
    }
    close($mh);
}

sub scanman_md_dir {
    my ($d) = @_;
    opendir(my $dh, $d) ||
        die "Can't opendir: $!";
    my @mans = grep { /.md\z/ } readdir($dh);
    closedir $dh;
    for my $m (@mans) {
        checkmanpage("$d/$m");
    }
}

scanman_md_dir("$root/docs/libcurl");
scanman_md_dir("$root/docs/libcurl/opts");

open my $s, "<", "$root/docs/libcurl/symbols-in-versions";
while(<$s>) {
    if(/(^[^ \n]+) +(.*)/) {
        my ($sym, $rest)=($1, $2);
        my @a=split(/ +/, $rest);
        push @syms, $sym;

        $symadded{$sym}=$a[0];
    }
}
close $s;

my $ignored=0;
for my $e (sort @syms) {
    if( $manpage{$e} ) {

        if( $manpage{$e} ne $symadded{$e} ) {
            printf "%s.md says version %s, but SIV says %s\n",
                $e, $manpage{$e}, $symadded{$e};
            $error++;
        }

    }
}
print "OK\n" if(!$error);
exit $error;