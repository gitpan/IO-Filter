#!/usr/bin/perl -w
# -*- cperl -*-

use strict;
use Test;
use IO::File;

BEGIN { plan tests => 10 }

use IO::Filter::uc;

ok (1);

my $tmpname = ".uc.t.$$";

my $io = new IO::File (">$tmpname") or die "$tmpname: $!";
my $fio = new IO::Filter::uc ($io, "w");

$fio->print ("this is some text\n") or die "print: $!";
$fio->print ("this is the second line\n") or die "print: $!";
$fio->print ("THIS IS THE THIRD line\n") or die "print: $!";
$fio->print ("this is the last line\n") or die "print: $!";
$fio->close;

ok (1);

$io = new IO::File ("<$tmpname") or die "$tmpname: $!";
my $line = $io->getline;
ok ($line eq "THIS IS SOME TEXT\n");
$line = $io->getline;
ok ($line eq "THIS IS THE SECOND LINE\n");
$line = $io->getline;
ok ($line eq "THIS IS THE THIRD LINE\n");
$line = $io->getline;
ok ($line eq "THIS IS THE LAST LINE\n");

$io = new IO::File (">$tmpname") or die "$tmpname: $!";
$io->print ("this is some more text\n") or die "print: $!";
$io->print ("second line\n") or die "print: $!";
$io->print ("THIRD line\n") or die "print: $!";
$io->print ("the very last line\n") or die "print: $!";
$io->close;

$io = new IO::File ("<$tmpname") or die "$tmpname: $!";
$fio = new IO::Filter::uc ($io, "r");

$line = $fio->getline;
ok ($line eq "THIS IS SOME MORE TEXT\n");
$line = $fio->getline;
ok ($line eq "SECOND LINE\n");
$line = $fio->getline;
ok ($line eq "THIRD LINE\n");
$line = $fio->getline;
ok ($line eq "THE VERY LAST LINE\n");

unlink $tmpname;
