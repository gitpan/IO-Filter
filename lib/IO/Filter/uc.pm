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

# $Id: uc.pm,v 1.1 2001/09/01 17:13:42 rich Exp $

=pod

=head1 NAME

IO::Filter::uc - Convert all characters in input to uppercase

=head1 SYNOPSIS

  use IO::Filter::uc;

  $io = ...; # any IO handle
  $fio = new IO::Filter::uc ($io, "r");
  # then you can read uppercase only bytes from $fio

  $io = ...; # any IO handle
  $fio = new IO::Filter::uc ($io, "w");
  # write bytes to $fio, they are written in uppercase to $io

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package IO::Filter::uc;

use strict;

use vars qw($VERSION $RELEASE);

$VERSION = '0.01';
$RELEASE = 1;

use IO::Filter;

use vars qw(@ISA);

@ISA = qw(IO::Filter);

# Non-optional modules.
use Carp;

=item $fio = new IO::Filter::uc ($io, $mode);

=cut

sub new
  {
    my $class = shift;
    my $io = shift;
    my $mode = shift;

    croak "mode (second argument) must be 'r' or 'w'"
      unless $mode eq 'r' || $mode eq 'w';

    my $self = $class->SUPER::new ();
    $self->{mode} = $mode;
    $self->{io} = $io;
    return bless $self, $class;
  }

sub syswrite
  {
    my $self = shift;

    $self->{mode} eq 'w' or croak "syswrite: handle not opened for writing";

    my $buffer = uc (defined $_[1] ? substr ($_[0], $_[2] || 0, $_[1])
		                   : $_[0]);

    syswrite $self->{io}, $buffer;
  }

sub sysread
  {
    my $self = shift;

    $self->{mode} eq 'r' or croak "sysread: handle not opened for reading";

    my $buffer;

    my $r = sysread $self->{io}, $buffer, $_[1];
    return undef unless defined $r;

    $buffer = uc $buffer;

    (defined $_[2] ? substr ($_[0], $_[2] || 0, $_[1]) : $_[0]) = $buffer;

    return $r;
  }

sub close
  {
    my $self = shift;

    $self->SUPER::close or return undef;

    close $self->{io};
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
