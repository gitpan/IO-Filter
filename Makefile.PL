# $Id: Makefile.PL,v 1.2 2001/09/01 17:13:40 rich Exp $
# -*- perl -*-

# IO::Filter - generic filters for IO handles
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

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => "IO::Filter",
	      VERSION_FROM => "lib/IO/Filter.pm",

	      DEFINE => '',
	      LIBS => [''],
	      INC => '',

	      dist =>
	      {
	       COMPRESS => 'gzip --force --best',
	       PREOP => 'cp IO-Filter.spec $(DISTVNAME)',
	      },

	      clean =>
	      {
	       FILES => '*.bak *~',
	      },

	      realclean =>
	      {
	       FILES => 'IO-Filter.spec',
	      },

	      depend =>
	      {
	       dist => 'IO-Filter.spec',
	      },
	     );

package MY;

sub libscan
  {
    my ($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
  }

sub postamble
  {
    '
check-manifest:
	@for d in `find -type d -name CVS`; \
	do \
	b=`dirname $$d`/; \
	awk -F/ \'$$1 != "D" {print $$2}\' $$d/Entries | \
	sed -e "s|^|$$b|" -e "s|^\./||"; \
	done | sort > .check-manifest; \
	sort MANIFEST > .orig-manifest; \
	diff -u .orig-manifest .check-manifest; \
	rm -f .orig-manifest .check-manifest
';
  }

__END__
