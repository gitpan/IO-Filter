#!/usr/bin/perl -w
# -*- cperl -*-

use strict;
use Test;
use IO::File;

BEGIN { plan tests => 10 }

use IO::Filter::lc;

ok (1);

my $tmpname = ".lc.t.$$";

my $io = new IO::File (">$tmpname") or die "$tmpname: $!";
my $fio = new IO::Filter::lc ($io, "w");

$fio->print ("THIS IS SOME TEXT\n") or die "print: $!";
$fio->print ("this is the second line\n") or die "print: $!";
$fio->print ("THIS IS THE THIRD line\n") or die "print: $!";
$fio->print ("this is the LAST LINE\n") or die "print: $!";
$fio->close;

ok (1);

$io = new IO::File ("<$tmpname") or die "$tmpname: $!";
my $line = $io->getline;
ok ($line eq "this is some text\n");
$line = $io->getline;
ok ($line eq "this is the second line\n");
$line = $io->getline;
ok ($line eq "this is the third line\n");
$line = $io->getline;
ok ($line eq "this is the last line\n");

$io = new IO::File (">$tmpname") or die "$tmpname: $!";
$io->print ("this is some MORE TEXT\n") or die "print: $!";
$io->print ("second line\n") or die "print: $!";
$io->print ("THIRD line\n") or die "print: $!";
$io->print ("THE VERY LAST line\n") or die "print: $!";
$io->close;

$io = new IO::File ("<$tmpname") or die "$tmpname: $!";
$fio = new IO::Filter::lc ($io, "r");

$line = $fio->getline;
ok ($line eq "this is some more text\n");
$line = $fio->getline;
ok ($line eq "second line\n");
$line = $fio->getline;
ok ($line eq "third line\n");
$line = $fio->getline;
ok ($line eq "the very last line\n");

unlink $tmpname;
