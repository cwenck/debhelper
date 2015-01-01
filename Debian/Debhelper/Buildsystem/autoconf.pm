# A debhelper build system class for handling Autoconf based projects
#
# Copyright: © 2008 Joey Hess
#            © 2008-2009 Modestas Vainius
# License: GPL-2+

package Debian::Debhelper::Buildsystem::autoconf;

use strict;
use Debian::Debhelper::Dh_Lib qw(dpkg_architecture_value sourcepackage compat);
use base 'Debian::Debhelper::Buildsystem::makefile';

sub DESCRIPTION {
	"GNU Autoconf (configure)"
}

sub check_auto_buildable {
	my $this=shift;
	my ($step)=@_;

	# Handle configure; the rest - next class (compat with 7.0.x code path)
	if ($step eq "configure") {
		return 1 if -x $this->get_sourcepath("configure");
	}
	return 0;
}

sub configure {
	my $this=shift;

	# Standard set of options for configure.
	my @opts;
	push @opts, "--build=" . dpkg_architecture_value("DEB_BUILD_GNU_TYPE");
	push @opts, "--prefix=/usr";
	push @opts, "--includedir=\${prefix}/include";
	push @opts, "--mandir=\${prefix}/share/man";
	push @opts, "--infodir=\${prefix}/share/info";
	push @opts, "--sysconfdir=/etc";
	push @opts, "--localstatedir=/var";
	if (defined $ENV{DH_VERBOSE} && $ENV{DH_VERBOSE} ne "") {
		push @opts, "--disable-silent-rules";
	}
	my $multiarch=dpkg_architecture_value("DEB_HOST_MULTIARCH");
	if (! compat(8)) {
	       if (defined $multiarch) {
			push @opts, "--libdir=\${prefix}/lib/$multiarch";
			push @opts, "--libexecdir=\${prefix}/lib/$multiarch";
		}
		else {
			push @opts, "--libexecdir=\${prefix}/lib";
		}
	}
	else {
		push @opts, "--libexecdir=\${prefix}/lib/" . sourcepackage();
	}
	push @opts, "--disable-maintainer-mode";
	push @opts, "--disable-dependency-tracking";
	# Provide --host only if different from --build, as recommended in
	# autotools-dev README.Debian: When provided (even if equal)
	# autoconf 2.52+ switches to cross-compiling mode.
	if (dpkg_architecture_value("DEB_BUILD_GNU_TYPE")
	    ne dpkg_architecture_value("DEB_HOST_GNU_TYPE")) {
		push @opts, "--host=" . dpkg_architecture_value("DEB_HOST_GNU_TYPE");
	}

	$this->mkdir_builddir();
	eval {
		$this->doit_in_builddir($this->get_source_rel2builddir("configure"), @opts, @_);
	};
	if ($@) {
		if (-e $this->get_buildpath("config.log")) {
			$this->doit_in_builddir("tail -v -n +0 config.log");
		}
		die $@;
	}
}

1

# Local Variables:
# indent-tabs-mode: t
# tab-width: 4
# cperl-indent-level: 4
# End:
