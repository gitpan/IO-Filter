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

# $Id: sort.pm,v 1.2 2001/09/01 17:13:42 rich Exp $

=pod

=head1 NAME

IO::Filter::sort - Sort compression filter

=head1 SYNOPSIS

  use IO::Filter::sort;

  $io = ...; # any IO handle
  $fio = new IO::Filter::sort ($io, "r");
  # then you can read sorted lines from $fio

  $io = ...; # any IO handle
  $fio = new IO::Filter::sort ($io, "w");
  # write lines to $fio, they are written sorted to $io

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package IO::Filter::sort;

use strict;

use vars qw($VERSION $RELEASE);

$VERSION = '0.01';
$RELEASE = 1;

use IO::Filter::External;

use vars qw(@ISA);

@ISA = qw(IO::Filter::External);

# Non-optional modules.
use Carp;

=item $fio = new IO::Filter::sort ($io, $mode);

=cut

sub new
  {
    my $class = shift;
    my $io = shift;
    my $mode = shift;

    croak "mode (second argument) must be 'r' or 'w'"
      unless $mode eq 'r' || $mode eq 'w';

    my $self = $class->SUPER::new ($io, $mode, "sort");
    return bless $self, $class;
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
