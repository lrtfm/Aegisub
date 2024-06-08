#!/bin/bash

# Ref:
#   https://github.com/TypesettingTools/Aegisub/issues/191#issuecomment-2061725745
#   https://github.com/TypesettingTools/Aegisub/issues/191#issuecomment-2156090845

set -e

brew install boost cmake ffmpeg ffms2 fftw \
    hunspell libass libiconv icu4c luarocks \
    meson ninja openal-soft pkg-config \
    portaudio pulseaudio uchardet wxwidgets zlib

# we need the libiconv from brew to get rid out of the errors on test
export MACOSX_DEPLOYMENT_TARGET=13
export LDFLAGS="-L$(brew --prefix)/opt/libiconv/lib"
export CPPFLAGS="-I$(brew --prefix)/opt/libiconv/include"
export PKG_CONFIG_PATH="$(brew --prefix)/opt/icu4c/lib/pkgconfig:$(brew --prefix)/opt/openal-soft/lib/pkgconfig"

# The dir with 000 permission can not be delete with `rm -rf` on macos.
if [[ -d build_static/data/dir_access_denied ]]; then
    chmod 744 build_static/data/dir_access_denied
fi

meson setup --wipe \
    -Ddefault_library=static \
    -Dbuildtype=debugoptimized \
    -Dbuild_osx_bundle=true \
    -Dlocal_boost=true \
    build_static
meson compile -C build_static
meson test -C build_static --verbose
meson compile -C build_static osx-bundle

# reference:
#   section "Ad hoc signing" in https://wiki.freepascal.org/Code_Signing_for_macOS
codesign --sign - --force --deep build_static/Aegisub.app

meson compile -C build_static osx-build-dmg
