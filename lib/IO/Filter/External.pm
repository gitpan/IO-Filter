#!/usr/bin/perl -w -T
# -*- perl -*-

# IO::Filter - generic filters for IO handles.
# Copyright (C) 2000 Bibliotech Ltd., Unit 2-3, 50 Carnwath Road,
# London, SW6 3EG, United Kingdom.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# $Id: External.pm,v 1.5 2001/09/01 17:13:41 rich Exp $

=pod

=head1 NAME

IO::Filter::External - Filter any IO handle using an external program.

=head1 SYNOPSIS

  use IO::Filter::External;

  $io = ...; # any IO handle opened in read mode
  $fio = new IO::Filter::External ($io, "r", "bzip2", "-c");
  # then you can read bzip-compressed bytes from $fio

  $io = ...; # any IO handle opened in write mode
  $fio = new IO::Filter::External ($io, "w", "bzip2", "-cd");
  # write bzip-compressed bytes to $fio

=head1 DESCRIPTION

C<IO::Filter::External> is an IO filter (see C<IO::Filter(3)>) which
allows you to filter any ordinary Perl IO handle through an arbitrary
Unix filter command. (The Unix filter command must be one of those
like C<tr> or C<grep> which takes input from STDIN and writes its
output to STDOUT).

C<IO::Filter::External> can be used in two modes, read mode or write mode.
All C<IO::Filter>s are unidirectional, and therefore cannot be used in
both read and write mode together.

Here is an example of read mode:

  $io = ...; # any IO handle opened in read mode
  $fio = new IO::Filter::External ($io, "r", "bzip2", "-c");
  # your program reads bzip-compressed bytes from $fio

In read mode, C<IO::Filter::External> behaves conceptually like this:

 your program         external          $io acts as
 reading from  <----- program    <----- the source
 $fio                 (bzip2 -c)        of data

Here is an example of write mode:

  $io = ...; # any IO handle opened in write mode
  $fio = new IO::Filter::External ($io, "w", "bzip2", "-cd");
  # your program writes bzip-compressed bytes to $fio

In write mode, the behaviour is:

 your program         external          $io acts as
 writing to    -----> program    -----> the sink for
 $fio                 (bzip2 -cd)       data

The implementation is somewhat more complex, since it
involves forking off I<two> external processes to avoid
deadlock. Therefore, you should look at the other classes
in the C<IO::Filter> package to see whether a Perl-only
optimized implementation exists for the task you are trying to
perform. For example, use C<IO::Filter::uc> instead of
trying for fork off an external C<tr> program.

=head1 METHODS

=over 4

=cut

package IO::Filter::External;

use strict;

use vars qw($VERSION $RELEASE);

$VERSION = '0.01';
$RELEASE = 1;

use IO::Pipe;
use IO::Filter;

use vars qw(@ISA);

@ISA = qw(IO::Filter);

# Non-optional modules.
use Carp;

=item $fio = new IO::Filter::External ($io, $mode, $cmd [, @args]));

=cut

sub new
  {
    my $class = shift;
    my $io = shift;
    my $mode = shift;
    my $cmd = shift;

    croak "mode (second argument) must be 'r' or 'w'"
      unless $mode eq 'r' || $mode eq 'w';

    # Create the two pipes.
    my $wr = new IO::Pipe () or return undef;
    my $rd = new IO::Pipe () or return undef;

    # Fork once to get to the buffer process.
    my $pid = fork;
    croak "fork failed: $!" unless defined $pid;

    if ($pid)			# Parent.
      {
	$wr->writer;
	$rd->reader;

	my $self = $class->SUPER::new ();
	$self->{wr} = $wr;
	$self->{rd} = $rd;
	$self->{mode} = $mode;
	$self->{io} = $io;
	return bless $self, $class;
      }

    # OK, we are now in the buffer process.
    $wr->reader;
    $rd->writer;

    # Create another pipe to go out to the external program.
    my $p3 = new IO::Pipe () or croak "pipe failed: $!";

    # Fork again to get to the external program.
    $pid = fork;
    croak "forked failed: $!" unless defined $pid;

    if ($pid)			# Parent (buffer process).
      {
	$p3->writer;
	$rd->close;
	_do_buffer ($wr, $p3);
	exit;
      }

    # OK, we are now in the external program process.
    $p3->reader;
    $wr->close;

    # Make STDOUT same as $rd.
    open STDOUT, ">&" . $rd->fileno or die "dup failed: $!";
    $rd->close;

    # Make STDIN same as $p3.
    open STDIN, "<&" . $p3->fileno or die "dup failed: $!";
    $p3->close;

    # Launch external command.
    exec $cmd, @_ or croak "exec: $cmd: $!";
  }

=item $fio->syswrite ($buffer [, $len [, $offset]]);

=cut

sub syswrite
  {
    my $self = shift;
    my $r;

    $self->{mode} eq 'w' or croak "syswrite: handle not opened for writing";

    # Write data into the output pipe.
    if (defined ($_[1])) {
      $r = syswrite $self->{wr}, $_[0], $_[1], $_[2] || 0
    } else {
      $r = syswrite $self->{wr}, $_[0]
    }

    return undef unless defined $r;

    # Keep sucking data from the read pipe and writing to $io until read
    # pipe blocks.
    my $rin = "";
    vec ($rin, $self->{rd}->fileno, 1) = 1;
    my $rout;
    my $buffer;

    while (select $rout=$rin, undef, undef, 0)
      {
	my $r2 = sysread $self->{rd}, $buffer, 4096;
	return undef unless defined $r2;
	$self->{io}->syswrite ($buffer, $r2) or return undef;
      }

    return $r;
  }

=item $fio->sysread ($buffer [, $len [, $offset]]);

=cut

sub sysread
  {
    my $self = shift;

    $self->{mode} eq 'r' or croak "sysread: handle not opened for reading";

    my $rin = "";
    vec ($rin, $self->{io}->fileno, 1) = 1 if exists $self->{io};
    vec ($rin, $self->{rd}->fileno, 1) = 1;
    my $rout;
    my $buffer;
    my $r;

    for (;;)
      {
	select $rout=$rin, undef, undef, undef or die "select: $!";

	if (exists $self->{io} && vec ($rout, $self->{io}->fileno, 1))
	  {
	    $r = sysread $self->{io}, $buffer, 4096;
	    return undef unless defined $r;
	    if ($r > 0)
	      {
		$self->{wr}->syswrite ($buffer, $r) or return undef;
	      }
	    else
	      {
		vec ($rin, $self->{io}->fileno, 1) = 0;
		$self->{io}->close or return undef;
		$self->{wr}->close or return undef;
		delete $self->{io};
		delete $self->{wr};
	      }
	  }

	if (vec ($rout, $self->{rd}->fileno, 1))
	  {
	    return sysread $self->{rd}, $_[0], $_[1], $_[2] || 0
	  }
      }
  }

=item $fio->close;

=cut

sub close
  {
    my $self = shift;

    $self->SUPER::close or return undef;

    if ($self->{mode} eq 'w')
      {
	$self->{wr}->close or return undef;

	# Wait for buffer process to exit.
	wait;

	# Keep reading from read pipe and writing to $io until EOF.
	for (;;)
	  {
	    my $buffer;
	    my $r = $self->{rd}->sysread ($buffer, 4096);
	    return undef unless defined $r;
	    last if $r == 0;
	    $self->{io}->syswrite ($buffer, $r) or return undef;
	  }

	$self->{rd}->close or return undef;
	$self->{io}->close or return undef;
      }
    else
      {
	# Wait for buffer process to exit.
	wait;

	$self->{rd}->close or return undef;
	if (exists $self->{io})
	  {
	    $self->{io}->close or return undef;
	  }
	if (exists $self->{wr})
	  {
	    $self->{wr}->close or return undef;
	  }
      }

    1;
  }

sub _do_buffer
  {
    my $rd = shift;
    my $wr = shift;

    my ($rin, $rout, $win, $wout, $buffer, $eof);

    $rin = "";
    vec ($rin, fileno ($rd), 1) = 1;
    $win = "";
    vec ($win, fileno ($wr), 1) = 1;

    $buffer = "";

    while (length $buffer > 0 || !$eof)
      {
	select $rout=$rin, $wout=$win, undef, undef
	  or die "select: $!";

	# Something to read?
	if (vec ($rout, fileno ($rd), 1))
	  {
	    my $r = $rd->sysread ($buffer, 4096, length $buffer);
	    die "sysread: $!" unless defined $r;

	    if ($r == 0)
	      {
		$eof = 1;
		$rin = "";
	      }
	  }

	# Something to write?
	if (vec ($wout, fileno ($wr), 1))
	  {
	    my $r = $wr->syswrite ($buffer, 4096, 0);
	    die "syswrite: $!" unless defined $r;

	    substr $buffer, 0, $r, "";
	  }
      }
  }

1 # So that the require or use succeeds.

__END__

=back 4

=head1 BUGS

=head1 FILES

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2001 Richard Jones (rich@annexia.org).

=head1 SEE ALSO

L<IO::Filter(3)>,
L<perl(1)>.

=cut
