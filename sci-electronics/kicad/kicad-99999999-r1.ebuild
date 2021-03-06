# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# rafaelmartins: Please try to keep the live ebuild synchronized with
# the latest snapshot ebuild. e.g.:
# cp kicad-YYYYMMDD_pXXXX.ebuild kicad-99999999-r1.ebuild

EAPI="3"
PYTHON_DEPEND=2

WX_GTK_VER="2.8"

inherit cmake-utils wxwidgets fdo-mime gnome2-utils bzr python flag-o-matic

DESCRIPTION="Electronic Schematic and PCB design tools."
HOMEPAGE="http://www.kicad-pcb.org"

SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
EBZR_REPO_URI="lp:kicad"

KEYWORDS=""
if [[ "${PV}" != "99999999" ]]; then
	KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
fi

IUSE="dev-doc debug doc examples minimal python nanometr gost sexpr"

CDEPEND="x11-libs/wxGTK:2.8[X,opengl,gnome]"
DEPEND="${CDEPEND}
	>=dev-util/cmake-2.6.0
	>=dev-libs/boost-1.40[python?]
	app-arch/xz-utils
	dev-doc? ( app-doc/doxygen )"
RDEPEND="${CDEPEND}
	sys-libs/zlib
	sci-electronics/electronics-menu"

pkg_setup() {
	python_set_active_version 2
}

src_unpack() {
	if [[ "${PV}" != "99999999" ]]; then
		EBZR_REVISION="${PV#*_p}"
	fi
	bzr_src_unpack

	if [[ "${PV}" = "99999999" ]]; then
		EBZR_REVISION=""
	else
		local date="${PV%_p*}"
		EBZR_REVISION="before:${date:0:4}-${date:4:2}-${date:6:2},23:59:59"
	fi

	# FIXME: we need to send patches for bzr.eclass, to avoid the weird
	# declarations of ${P} below.

	if ! use minimal; then
		EBZR_REPO_URI="lp:~kicad-lib-committers/kicad/library" \
			EBZR_PROJECT="kicad-library" \
			P="${P}/kicad-library" \
			EBZR_CACHE_DIR="kicad-library" \
			bzr_fetch
	fi

	if use doc; then
		EBZR_REPO_URI="lp:~kicad-developers/kicad/doc" \
			EBZR_PROJECT="kicad-doc" \
			P="${P}/kicad-doc" \
			EBZR_CACHE_DIR="kicad-doc" \
			bzr_fetch
	fi
}

src_prepare() {
	sed -i \
		-e '/add_subdirectory(template)/ a \
			add_subdirectory(kicad-doc)\
			add_subdirectory(kicad-library)' \
		-e 's/create_svn_version_header()/#create_svn_version_header()/' \
		-e 's/ -O2 / /' \
		CMakeLists.txt || die 'sed failed'

	sed -i \
		-e 's/Scientific;Development/Engineering;Electronics/' \
		resources/linux/mime/applications/*.desktop || die 'sed failed'

	# Use native boost
	sed -i -e '/Boost/s/^#check_find_package/check_find_package/' \
		-e '/Boost/s/^#find_package/find_package/' CMakeLists.txt || die "sed failed"

	# Add important doc files
	sed -i -e 's/INSTALL.txt/AUTHORS.txt CHANGELOG.txt README.txt TODO.txt/' CMakeLists.txt || die "sed failed"

	# Fix desktop files
	rm resources/linux/mime/applications/eeschema.desktop
	sed -i -e 's/Development;//' resources/linux/mime/applications/kicad.desktop || die "sed failed"

	# Handle optional minimal install
	if use minimal ; then
		sed -i -e '/add_subdirectory(template)/d' \
			-e '/add_subdirectory(kicad-library)/d' CMakeLists.txt || die "sed failed"
	fi

	# Add documentation and fix necessary code if requested
	if use doc ; then
		sed -i -e "s/subdirs.Add( wxT( \"kicad\" ) );/subdirs.Add( wxT( \"${PF}\" ) );/" \
			-e '/subdirs.Add( _T( "help" ) );/d' common/edaappl.cpp || die "sed failed"
	else
		sed -i -e '/add_subdirectory(kicad-doc)/d' CMakeLists.txt || die "sed failed"
	fi

	# Install examples in the right place if requested
	if use examples ; then
		sed -i -e 's:${KICAD_DATA}/demos:${KICAD_DOCS}/examples:' CMakeLists.txt || die "sed failed"
	else
		sed -i -e '/add_subdirectory(demos)/d' CMakeLists.txt || die "sed failed"
	fi
}

src_configure() {
	if use amd64;then
		append-cxxflags -fPIC
	fi
	need-wxwidgets unicode

	mycmakeargs="${mycmakeargs}
		-DKICAD_MINIZIP=OFF
		-DKICAD_CYRILLIC=ON
		-DwxUSE_UNICODE=ON
		$(cmake-utils_use gost KICAD_GOST)
		$(cmake-utils_use nanometr USE_PCBNEW_NANOMETRES)
		$(cmake-utils_use sexpr USE_PCBNEW_SEXPR_FILE_FORMAT)
		-DKICAD_AUIMANAGER=OFF
		-DKICAD_AUITOOLBAR=OFF
		$(cmake-utils_use python KICAD_SCRIPTING)
		$(cmake-utils_use python KICAD_SCRIPTING_MODULES)
		-DKICAD_DOCS=/usr/share/doc/${PF}
		-DKICAD_HELP=/usr/share/doc/${PF}"

	if [[ "${PV}" = "99999999" ]]; then
		mycmakeargs="${mycmakeargs} -DKICAD_TESTING_VERSION=ON"
		echo "======Testing====="
	else
		mycmakeargs="${mycmakeargs} -DKICAD_STABLE_VERSION=ON"
	fi

	cmake-utils_src_configure
}

src_compile() {
	use dev-doc && doxygen Doxyfile
}

src_install() {
	cmake-utils_src_install
	if use dev-doc ; then
		insinto /usr/share/doc/${PF}
		doins uncrustify.cfg
		cd Documentation
		doins -r GUI_Translation_HOWTO.pdf guidelines/UIpolicies.txt doxygen/doxygen
	fi
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update

	if use minimal ; then
		ewarn "If the schematic and/or board editors complain about missing libraries when you"
		ewarn "open old projects, you will have to take one or more of the following actions :"
		ewarn "- Install the missing libraries manually."
		ewarn "- Remove the libraries from the 'Libs and Dir' preferences."
		ewarn "- Fix the libraries' locations in the 'Libs and Dir' preferences."
		ewarn "- Emerge kicad without the 'minimal' USE flag."
		elog
	fi
	elog "You may want to emerge media-gfx/wings if you want to create 3D models of components."
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	fdo-mime_mime_database_update
	gnome2_icon_cache_update
}
