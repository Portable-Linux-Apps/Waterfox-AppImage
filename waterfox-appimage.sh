#!/bin/sh

set -ex

export ARCH=$(uname -m)
APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
export URUNTIME_PRELOAD=1 # really needed here

tarball_url="https://cdn1.waterfox.net/waterfox/releases/latest/linux"
wget "$tarball_url" -O ./package.tar.bz2
tar xvf ./package.tar.bz2
rm -f ./package.tar.bz2

export VERSION=$(awk -F'=' '/Version/ {print $2; exit}' ./waterfox/application.ini)
echo "$VERSION" > ~/version

mv -v ./waterfox ./AppDir && (
	cd ./AppDir
	cp -v ./browser/chrome/icons/default/default128.png ./waterfox.png
	cp -v ./browser/chrome/icons/default/default128.png ./.DirIcon

	cat > ./AppRun <<- 'KEK'
	#!/bin/sh
	CURRENTDIR="$(cd "${0%/*}" && echo "$PWD")"
	export PATH="${CURRENTDIR}:${PATH}"
	export MOZ_LEGACY_PROFILES=1          # Prevent per installation profiles
	export MOZ_APP_LAUNCHER="${APPIMAGE}" # Allows setting as default browser
	exec "${CURRENTDIR}/waterfox" "$@"
	KEK
	chmod +x ./AppRun

	# disable automatic updates
	mkdir -p ./distribution
	cat >> ./distribution/policies.json <<- 'KEK'
	{
	  "policies": {
	    "DisableAppUpdate": true,
	    "AppAutoUpdate": false,
	    "BackgroundAppUpdate": false
	  }
	}
	KEK

	cat > ./waterfox.desktop <<- 'KEK'
	# add desktop[ file
	[Desktop Entry]
	Name=Waterfox
	GenericName=Web Browser
	Comment=Browse the World Wide Web
	Keywords=Internet;WWW;Browser;Web;Explorer
	Exec=waterfox %u
	Icon=waterfox
	Terminal=false
	X-MultipleArgs=false
	Type=Application
	MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;application/x-xpinstall;
	StartupNotify=true
	StartupWMClass=waterfox
	Categories=Network;WebBrowser;
	Actions=new-window;new-private-window;safe-mode;

	[Desktop Action new-window]
	Name=New Window
	Exec=waterfox --new-window %u

	[Desktop Action new-private-window]
	Name=New Private Window
	Exec=waterfox --private-window %u

	[Desktop Action safe-mode]
	Name=Safe Mode
	Exec=waterfox -safe-mode %u
	KEK
)

wget "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool -n -u "$UPINFO" ./AppDir
