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

# $Id: Filter.pm,v 1.5 2001/09/01 17:13:41 rich Exp $

=pod

=head1 NAME

IO::Filter::* - Generic input/output filters for Perl IO handles.

=head1 SYNOPSIS

 use IO::Filter::External;
 use IO::Filter::bunzip2;
 use IO::Filter::bzip2;
 use IO::Filter::gunzip;
 use IO::Filter::gzip;
 use IO::Filter::lc;
 use IO::Filter::sort;
 use IO::Filter::uc;

 $io = # any Perl IO handle, eg. an IO::File or IO::Socket,
       # opened for writing
 $fio = new IO::Filter::gzip ($io, "w");
 $fio->print ("This text will be written gzip-compressed\n",
              "to the underlying \$io file or socket.\n");
 $fio->close; # also closes underlying $io

 $io = # any Perl IO handle opened for reading
 $fio1 = new IO::Filter::gzip ($io, "r");
 $fio2 = new IO::Filter::gunzip ($fio, "r");
 # reading from $fio2 is an expensive no-op

=head1 DESCRIPTION

C<IO::Filter::*> is a set of filter classes which allow you to
apply filters to ordinary Perl IO handles. In this way you can,
for example, compress data into and out of sockets directly,
perform on-the-fly data transformations and so on. You can
think of filters as being similar in some ways to Unix filter
commands (eg. C<sort>, C<tr>, C<grep>, etc.).

A filter wraps an existing IO handle and gives you back the
same interface (see L<IO::Handle(3)>), so you can use an
C<IO::Filter::*> object whenever you would use a normal
C<IO::Handle>.

Filters are always unidirectional, meaning that you can use them either
in read mode or write mode but not both at the same time.

B<Note:> C<IO::Filter> itself is an abstract superclass.  Do not
instantiate objects of type C<IO::Filter> directly. Instead, create
objects of one of the derived classes such as C<IO::Filter::gzip>.

=head1 METHODS

=over 4

=cut

package IO::Filter;

use strict;

use vars qw($VERSION $RELEASE);

$VERSION = '0.01';
$RELEASE = 1;

use Carp;

use constant BLOCKSIZE => 16384;

sub new
  {
    my $class = shift;

    my $self = {};
    $self->{inbuf} = "";
    $self->{outbuf} = "";
    return bless $self, $class;
  }

=item $fio->read ($buffer, $len [, $offset]);

=cut

sub read
  {
    my $self = shift;
    @_ == 2 || @_ == 3 or croak "\$io->read (BUF, LEN [, OFF])";

    my $n = $_[1];
    my $off = $_[2] || 0;

    for (;;)
      {
	# End of file and input buffer empty?
	if ($self->{eof} && 0 == length $self->{inbuf})
	  {
	    return 0;
	  }

	# Satisfy this from the input buffer directly?
	if ($self->{eof} || $n <= length $self->{inbuf})
	  {
	    my $len = length $self->{inbuf};

	    ($off ? substr ($_[0], $off, $n)
	          : $_[0])
	      = substr ($self->{inbuf}, 0, $n, "");

	    return $len;
	  }

	# Read more bytes into the input buffer.
	my $buffer;
	my $r = $self->sysread ($buffer, BLOCKSIZE);
	return undef unless defined $r;
	if ($r == 0)
	  {
	    $self->{eof} = 1;
	  }
	else
	  {
	    $self->{inbuf} .= $buffer;
	  }
      }
  }

=item $fio->write ($buffer, $len [, $offset]);

=cut

sub write
  {
    my $self = shift;
    @_ == 2 || @_ == 3 or croak "\$io->write (BUF, LEN [, OFF])";

    my $n = $_[1];
    my $off = $_[2] || 0;

    # Append data to the end of the output buffer.
    $self->{outbuf} .= substr ($_[0], $off, $n);

    # If the output buffer exceeds BLOCKSIZE, then flush it.
    if (length ($self->{outbuf}) >= BLOCKSIZE)
      {
	$self->flush or return undef;
      }

    return $n;
  }

=item $fio->flush;

=cut

sub flush
  {
    my $self = shift;

    my $n = length $self->{outbuf};
    my $len = $n;

    while ($len)
      {
	my $r = $self->syswrite ($self->{outbuf}, $len);
	return undef unless defined $r;
	substr ($self->{outbuf}, 0, $r, "");
	$len -= $r;
      }

    $n;
  }

=item $fio->getc;

=cut

sub getc
  {
    my $self = shift;

    my $c;
    $self->read ($c, 1) or return undef;
    return $c;
  }

=item $fio->getline;

=cut

sub getline
  {
    my $self = shift;

    my $line;
    my $c;
    while ($c = $self->getc)
      {
	$line = "" unless defined $line;
	$line .= $c;
	last if $c eq "\n";
      }

    return $line;
  }

=item $fio->print (@args);

=cut

sub print
  {
    my $self = shift;
    my $buffer = join ('', @_);
    $self->write ($buffer, length $buffer);
  }

=item $fio->printf ($fs, ...);

=cut

sub printf
  {
    my $self = shift;
    my $buffer = sprintf @_;
    $self->write ($buffer, length $buffer);
  }

=item $fio->close;

=cut

sub close
  {
    my $self = shift;
    my $r = $self->flush;
    defined $r ? 1 : undef;
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

L<IO::Filter::External(3)>,
L<IO::Filter::bunzip2(3)>,
L<IO::Filter::bzip2(3)>,
L<IO::Filter::gunzip(3)>,
L<IO::Filter::gzip(3)>,
L<IO::Filter::lc(3)>,
L<IO::Filter::sort(3)>,
L<IO::Filter::uc(3)>,
L<IO::Handle(3)>,
L<perl(1)>.

=cut
