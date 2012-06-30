# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3

DESCRIPTION="Appmenu support for Firefox"
HOMEPAGE="https://code.launchpad.net/~extension-hackers/globalmenu-extension"
SRC_URI="( x86? ( mirror://ubuntu/pool/main/f/firefox/firefox-globalmenu_${PV}~b6+build1-0ubuntu2_i386.deb )
		 amd64? ( mirror://ubuntu/pool/main/f/firefox/firefox-globalmenu_${PV}~b6+build1-0ubuntu2_amd64.deb )
		 )"

LICENSE="|| ( MPL-1.1 GPL-2 LGPL-2.1 )"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE=""

DEPEND="|| ( >=www-client/firefox-12.0 >=www-client/firefox-bin-12.0 )
		x11-misc/appmenu-gtk[gtk2]
		app-text/gnome-doc-utils"
RDEPEND="${DEPEND}"

S="${WORKDIR}"

QA_PRESTRIPPED="//usr/lib/firefox/extensions/globalmenu@ubuntu.com/components/libglobalmenu.so"

src_unpack() {
	unpack ${A}
	unpack ./data.tar.gz
}

src_install() {
	mv usr/lib/firefox-addons usr/lib/firefox
	cp -R usr "${D}"
	dosym "/usr/lib/firefox/extensions/globalmenu@ubuntu.com" "/opt/firefox/extensions/globalmenu@ubuntu.com"
}