#!/usr/bin/perl -w
# -*- cperl -*-

use strict;
use Test;
use IO::File;

BEGIN { plan tests => 4 }

use IO::Filter::bzip2;
use IO::Filter::bunzip2;

ok (1);

my $tmpname = ".bzip.t.$$";
my $original = "testing 1 2 3 4 ...\n";

my $io = new IO::File (">$tmpname") or die "$tmpname: $!";
my $fio = new IO::Filter::bzip2 ($io, "w");

$fio->print ($original) or die "print: $!";
$fio->close;

ok (1);

$io = new IO::File ("bzip2 -cd < $tmpname |") or die "$tmpname: $!";
my $buffer;
$io->read ($buffer, 1000) or die "read: $!";

ok ($buffer eq $original);

$io = new IO::File ("<$tmpname") or die "$tmpname: $!";
$fio = new IO::Filter::bunzip2 ($io, "r");

$fio->read ($buffer, 1000) or die "read: $!";

ok ($buffer eq $original);

unlink $tmpname;
