# Automatically generated by IO-Filter.spec.PL

%define perlsitearch %(perl -e 'use Config; print $Config{installsitearch}, "\\n"')
%define perlsitelib %(perl -e 'use Config; print $Config{installsitelib}, "\\n"')
%define perlman1dir %(perl -e 'use Config; print $Config{installman1dir}, "\\n"')
%define perlman3dir %(perl -e 'use Config; print $Config{installman3dir}, "\\n"')
%define perlversion %(perl -e 'use Config; print $Config{version}, "\\n"')

Summary: IO::Filter - generic filters for Perl IO handles
Name: IO-Filter
Version: 0.01
Release: 1
Copyright: GPL
Group: Applications/Internet
Source: %{name}-%{version}.tar.gz
BuildRoot: /var/tmp/%{name}-%{version}-root
Requires: Compress-Zlib >= 1.14
Requires: perl >= %{perlversion}

%description


%prep
%setup -q


%build
perl Makefile.PL
make
make test


%install
rm -rf $RPM_BUILD_ROOT
make PREFIX=$RPM_BUILD_ROOT/usr install
find $RPM_BUILD_ROOT/usr -type f -print | perl -p -e "s@^$RPM_BUILD_ROOT(.*)@\$1*@g" | grep -v perllocal.pod > %{name}-filelist

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{name}-filelist
%defattr(-,root,root)
