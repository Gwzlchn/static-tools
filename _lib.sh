# Shared orchestration for in-container static builds (POSIX sh / Alpine ash).
#
# A tool recipe (<tool>/build.sh) sources this, then declares:
#   TOOL=<name>                 # required
#   ARCHES="x86_64 riscv64"     # required (greppable; CI reads it to build the matrix)
#   DEFAULT_VERSION=<ver>       # required; used when VERSION is unset/"default"
#   latest_version() { ... }    # required; echoes the newest upstream version
#   build_tool() { ... }        # required; compiles, smoke-tests, sets BIN (+ optional BUILT_VERSION)
# ...and finally calls:  run_recipe
#
# The recipe only describes what is genuinely tool-specific (deps, source, flags,
# smoke test). Mirror setup, version resolution, static verification, stripping,
# naming and dist layout all live here.

# Point apk at a mirror when APK_MIRROR is set (local = USTC for speed). Empty/unset
# (CI on GitHub runners) keeps upstream mirrors, which are faster outside China.
setup_apk_mirror() {
  if [ -n "${APK_MIRROR:-}" ]; then
    _apk_v=$(. /etc/os-release; printf '%s' "$VERSION_ID")
    case "$_apk_v" in
      *[!0-9.]*) _apk_branch=edge ;;                                   # "edge" etc.
      *)         _apk_branch="v$(printf '%s' "$_apk_v" | cut -d. -f1,2)" ;;
    esac
    {
      echo "${APK_MIRROR%/}/${_apk_branch}/main"
      echo "${APK_MIRROR%/}/${_apk_branch}/community"
    } > /etc/apk/repositories
    echo "==> apk mirror: ${APK_MIRROR%/} (${_apk_branch})"
  else
    echo "==> apk mirror: upstream (default)"
  fi
  apk update -q
}

# Newest *stable* release tag (GitHub /releases/latest excludes prereleases/drafts),
# leading "v" stripped. Authenticates with GH_API_TOKEN when set (avoids the harsh
# unauthenticated rate limit on GitHub Actions runners). Usage: gh_latest_tag owner/repo
gh_latest_tag() {
  if [ -n "${GH_API_TOKEN:-}" ]; then
    wget -qO- --header="Authorization: Bearer ${GH_API_TOKEN}" "https://api.github.com/repos/$1/releases/latest"
  else
    wget -qO- "https://api.github.com/repos/$1/releases/latest"
  fi | sed -n 's/.*"tag_name" *: *"v\{0,1\}\([^"]*\)".*/\1/p' | head -n1
}

# Retry a command with linear backoff (handles flaky GitHub/network fetches).
# Usage: retry <attempts> <cmd...>
retry() {
  _n=$1; shift; _i=1
  while :; do
    "$@" && return 0
    [ "$_i" -ge "$_n" ] && { echo "!! failed after $_n attempts: $*" >&2; return 1; }
    echo "   attempt $_i/$_n failed; retrying in ${_i}s: $*" >&2
    sleep "$_i"; _i=$((_i + 1))
  done
}

# Resolve VERSION env -> concrete version:
#   unset|"" |default -> $DEFAULT_VERSION ;  latest -> latest_version() ;  else literal
pick_version() {
  case "${VERSION:-default}" in
    ''|default)
      if [ "$DEFAULT_VERSION" = latest ]; then latest_version
      else printf '%s\n' "$DEFAULT_VERSION"; fi ;;
    latest)     latest_version ;;
    *)          printf '%s\n' "$VERSION" ;;
  esac
}

# Lenient smoke check -- never fails the build on its own (finalize asserts static).
smoke() { "$1" --version 2>/dev/null || "$1" --help 2>/dev/null | head -1 || true; }

# Go tool via `go install <module>@v<ver>` (CGO off => static). GOPROXY honors the mirror.
# Usage: go_install <module/path> <binary-name> [ldflag-version-symbol]
go_install() {
  _mod=$1; _bin=$2; _vf=${3:-}
  apk add --no-cache go git ca-certificates file >/dev/null
  export CGO_ENABLED=0 GOFLAGS=-trimpath GOBIN=/tmp/gobin GOTOOLCHAIN=auto
  export GOPROXY="${GOPROXY:-https://proxy.golang.org,direct}"
  mkdir -p /tmp/gobin
  _ld="-s -w"; [ -n "$_vf" ] && _ld="$_ld -X ${_vf}=v${RESOLVED_VERSION}"
  retry 3 go install -ldflags "$_ld" "${_mod}@v${RESOLVED_VERSION}"
  BIN="/tmp/gobin/$_bin"
  smoke "$BIN"
}

# Go tool built from a cloned tag (for modules with `replace` directives that block
# `go install`). Usage: go_build <owner/repo> <pkg-rel-path> <binary-name>
go_build() {
  _repo=$1; _pkg=$2; _bin=$3
  apk add --no-cache go git ca-certificates file >/dev/null
  export CGO_ENABLED=0 GOFLAGS=-trimpath GOTOOLCHAIN=auto
  export GOPROXY="${GOPROXY:-https://proxy.golang.org,direct}"
  mkdir -p /tmp/gobin
  _clone() {
    rm -rf /tmp/gosrc
    git clone --depth 1 --branch "v${RESOLVED_VERSION}" "https://github.com/${_repo}.git" /tmp/gosrc 2>/dev/null \
      || git clone --depth 1 --branch "${RESOLVED_VERSION}" "https://github.com/${_repo}.git" /tmp/gosrc
  }
  retry 4 _clone
  ( cd /tmp/gosrc && go build -ldflags "-s -w" -o "/tmp/gobin/${_bin}" "$_pkg" )
  BIN="/tmp/gobin/$_bin"
  smoke "$BIN"
}

# Set up latest stable Rust via rustup (musl host => static by default), plus common
# build-script deps (python3/git/perl/cmake/openssl). Shared by the cargo_* helpers.
# Alpine's packaged rustc lags behind newest crates' MSRV, hence rustup.
_rustup() {
  apk add --no-cache rustup build-base cmake pkgconf perl file python3 git \
    openssl-dev openssl-libs-static >/dev/null
  export RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
  rustup-init -y --no-modify-path --profile minimal \
    --default-toolchain stable --default-host x86_64-unknown-linux-musl >/dev/null 2>&1
  export PATH="/opt/cargo/bin:$PATH"
  # The musl target is static by default; forcing crt-static globally breaks proc-macros.
  export OPENSSL_STATIC=1 OPENSSL_NO_VENDOR=1
  if [ -n "${CARGO_MIRROR:-}" ]; then
    printf '[source.crates-io]\nreplace-with="m"\n[source.m]\nregistry="%s"\n' "$CARGO_MIRROR" \
      > "$CARGO_HOME/config.toml"
  fi
}

# Rust tool from crates.io (latest stable). Usage: cargo_install <crate> <binary-name>
cargo_install() {
  _crate=$1; _bin=$2
  _rustup
  retry 2 cargo install "$_crate" --root /tmp/rust --locked \
    || cargo install "$_crate" --root /tmp/rust
  BIN="/tmp/rust/bin/$_bin"
  _v=$(sed -n "s/^\"$_crate \([0-9][^ ]*\) .*/\1/p" /tmp/rust/.crates.toml 2>/dev/null | head -1)
  [ -n "$_v" ] && RESOLVED_VERSION="$_v"
  smoke "$BIN"
}

# Rust tool built from a cloned git tag (for crates whose build.rs needs the git repo,
# e.g. gitui embeds the commit hash). Usage: cargo_build_git <owner/repo> <binary-name>
cargo_build_git() {
  _repo=$1; _bin=$2
  _rustup
  _rclone() {
    rm -rf /tmp/rsrc
    git clone --depth 1 --branch "v${RESOLVED_VERSION}" "https://github.com/${_repo}.git" /tmp/rsrc 2>/dev/null \
      || git clone --depth 1 --branch "${RESOLVED_VERSION}" "https://github.com/${_repo}.git" /tmp/rsrc
  }
  retry 4 _rclone
  ( cd /tmp/rsrc && cargo build --release --locked )
  BIN="/tmp/rsrc/target/release/$_bin"
  smoke "$BIN"
}

# finalize <built-binary> <toolname> <version>
# Strips, asserts the binary is static, copies into /work/dist/<arch>/ under a plain
# and a versioned name, records the version, and hands ownership back to the host.
finalize() {
  _src=$1; _tool=$2; _ver=$3
  _arch=$(uname -m)
  strip "$_src" 2>/dev/null || true

  _ftype=$(file -b "$_src")
  echo "==> file: $_ftype"
  # Accept "statically linked" and "static-pie linked"; reject only dynamically linked.
  case "$_ftype" in
    *"dynamically linked"*) echo "!!! dynamically linked -- aborting" >&2; exit 1 ;;
    *ELF*)                   echo "==> static link: OK" ;;
    *)                       echo "!!! not an ELF executable -- aborting" >&2; exit 1 ;;
  esac

  _out="/work/dist/${_arch}"
  mkdir -p "$_out"
  cp "$_src" "$_out/${_tool}"
  cp "$_src" "$_out/${_tool}-${_ver}-linux-${_arch}-static"
  printf '%s\n' "$_ver" > "$_out/${_tool}.version"
  chown -R "${HOST_UID:-1000}:${HOST_GID:-${HOST_UID:-1000}}" /work/dist 2>/dev/null \
    || echo "warn: chown of /work/dist failed" >&2
  echo "==> exported $_out/${_tool}  ($(du -h "$_out/${_tool}" | cut -f1), ${_ver})"
}

# Orchestrate: mirror -> version -> build_tool -> finalize.
# build_tool reads $RESOLVED_VERSION, must set $BIN, may set $BUILT_VERSION
# (e.g. tmux appends the git short rev to the reported version).
run_recipe() {
  : "${TOOL:?recipe must set TOOL}"
  : "${DEFAULT_VERSION:?recipe must set DEFAULT_VERSION}"
  setup_apk_mirror
  RESOLVED_VERSION="$(pick_version)"
  : "${RESOLVED_VERSION:?could not resolve version}"
  echo "==> $TOOL: building '$RESOLVED_VERSION' for $(uname -m)"
  build_tool
  finalize "${BIN:?build_tool did not set BIN}" "$TOOL" "${BUILT_VERSION:-$RESOLVED_VERSION}"
}
