#!/usr/bin/perl -w
# -*- cperl -*-

use strict;
use Test;
use IO::File;

BEGIN { plan tests => 10 }

use IO::Filter::sort;

ok (1);

my $tmpname = ".sort.t.$$";

my $io = new IO::File (">$tmpname") or die "$tmpname: $!";
my $fio = new IO::Filter::sort ($io, "w");

$fio->print ("line 2\n") or die "print: $!";
$fio->print ("line 4\n") or die "print: $!";
$fio->print ("line 1\n") or die "print: $!";
$fio->print ("line 3\n") or die "print: $!";
$fio->close;

ok (1);

$io = new IO::File ("<$tmpname") or die "$tmpname: $!";
my $line = $io->getline;
ok ($line eq "line 1\n");
$line = $io->getline;
ok ($line eq "line 2\n");
$line = $io->getline;
ok ($line eq "line 3\n");
$line = $io->getline;
ok ($line eq "line 4\n");

$io = new IO::File (">$tmpname") or die "$tmpname: $!";
$io->print ("line 2\n") or die "print: $!";
$io->print ("line 4\n") or die "print: $!";
$io->print ("line 1\n") or die "print: $!";
$io->print ("line 3\n") or die "print: $!";
$io->close;

$io = new IO::File ("<$tmpname") or die "$tmpname: $!";
$fio = new IO::Filter::sort ($io, "r");

$line = $fio->getline;
ok ($line eq "line 1\n");
$line = $fio->getline;
ok ($line eq "line 2\n");
$line = $fio->getline;
ok ($line eq "line 3\n");
$line = $fio->getline;
ok ($line eq "line 4\n");

unlink $tmpname;
