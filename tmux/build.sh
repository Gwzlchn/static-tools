#!/bin/sh
# tmux -- fully static (musl + -static): Alpine's static libevent + a source-built
# static ncursesw (source build pins the terminfo search path; Alpine's ncurses only
# looks in /etc/terminfo, which breaks on a Debian/NAS host using /usr/share/terminfo).
# DEFAULT is "master" (the next-3.7 dev line); any git tag (e.g. 3.6b) also works.
set -eu
. "$(dirname "$0")/../_lib.sh"

TOOL=tmux
ARCHES="x86_64"
DEFAULT_VERSION=master

# "latest" == master for tmux (newest dev code, reports next-3.7).
latest_version() { echo master; }

build_tool() {
  PREFIX=/opt/static
  NCURSES_VER=6.5
  JOBS=$(nproc)

  # libevent comes from Alpine's static package (resolved via the apk mirror) -- no
  # foreign download and no compile. Only ncurses is built from source (see below).
  apk add --no-cache build-base autoconf automake pkgconf bison \
    libevent-static libevent-dev \
    git wget tar xz file ncurses-terminfo-base >/dev/null

  mkdir -p "$PREFIX" /build
  cd /build

  echo "==== ncurses ${NCURSES_VER} (static, widec) ===="
  # GNU_MIRROR is set to a CN mirror for local builds; empty in CI (-> upstream).
  gnu="${GNU_MIRROR:-https://ftp.gnu.org/gnu}"
  retry 3 wget -q "${gnu%/}/ncurses/ncurses-${NCURSES_VER}.tar.gz" \
    || retry 3 wget -q "https://invisible-mirror.net/archives/ncurses/ncurses-${NCURSES_VER}.tar.gz"
  tar xf ncurses-*.tar.gz
  # Broad terminfo search so the binary finds terminfo on Alpine (/etc/terminfo),
  # Debian/NAS (/usr/share/terminfo) and elsewhere.
  ( cd "ncurses-${NCURSES_VER}"
    ./configure --prefix="$PREFIX" \
      --without-shared --without-debug --without-ada --without-cxx-binding \
      --enable-widec --enable-pc-files \
      --with-pkg-config-libdir="$PREFIX/lib/pkgconfig" \
      --with-default-terminfo-dir=/usr/share/terminfo \
      --with-terminfo-dirs="/etc/terminfo:/lib/terminfo:/usr/share/terminfo" >/dev/null
    make -j"$JOBS" >/dev/null && make install >/dev/null )

  echo "==== tmux ${RESOLVED_VERSION} ===="
  clone_tmux() {
    rm -rf tmux
    if [ "$RESOLVED_VERSION" = master ]; then
      git clone --depth 1 https://github.com/tmux/tmux.git
    else
      git clone --depth 1 --branch "$RESOLVED_VERSION" https://github.com/tmux/tmux.git
    fi
  }
  retry 4 clone_tmux
  cd tmux
  REV=$(git rev-parse --short HEAD)
  sh autogen.sh >/dev/null
  export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig"
  # --enable-static makes tmux add -static and use `pkgconf --static`.
  ./configure --enable-static \
    CPPFLAGS="-I$PREFIX/include -I$PREFIX/include/ncursesw" \
    LDFLAGS="-L$PREFIX/lib" >/dev/null
  make -j"$JOBS" >/dev/null

  BUILT_VERSION="$(./tmux -V | awk '{print $2}')-${REV}"   # e.g. next-3.7-abc1234

  echo "==== smoke test ===="
  export TERM=xterm
  ./tmux -V
  # Isolated socket name -- never touch the default tmux server.
  _sock="stbuild-$$"
  ./tmux -L "$_sock" new-session -d -s smoke 'sleep 5'
  ./tmux -L "$_sock" has-session -t smoke && echo "==> smoke: detached session is up"
  ./tmux -L "$_sock" list-sessions
  ./tmux -L "$_sock" kill-server 2>/dev/null || true

  BIN="$PWD/tmux"
}

run_recipe
