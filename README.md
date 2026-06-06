# static-tools

Reproducible **fully-static** Linux binaries of common tools, built with **musl**
inside throwaway Alpine containers. One binary, no runtime dependencies — drop it
anywhere (glibc or musl host, any distro) and run.

Currently (all x86_64 unless noted):
- **C/C++:** tmux (`next-3.7`), rsync (+riscv64), jq, htop, curl, btop
- **Go:** fzf, rclone, lazygit, micro, yq, croc, gdu, age, duf, dasel, sops
- **Rust:** ripgrep, fd, bat, eza, sd, delta, zoxide, just, hyperfine, procs, gitui, xh, gping, dust

(jless is intentionally omitted: its hard `clipboard`→X11 dependency can't be cleanly
static-linked on musl.)

Go tools build via `go install` (CGO off), Rust via `cargo install` (musl + `crt-static`),
C/C++ from source against Alpine static libs — all fully static, all in `_lib.sh` helpers.

## Build locally

Nothing is installed on your host — only Docker is used.

```sh
./build.sh tmux                 # tmux, x86_64, tool's default version
./build.sh rsync x86_64         # rsync, x86_64
./build.sh rsync riscv64        # rsync, riscv64 (auto-registers QEMU, ephemeral)
./build.sh rsync x86_64 latest  # pin to the newest upstream release
./build.sh rsync x86_64 3.4.0   # pin to an explicit version
```

Output lands in `dist/<arch>/`:
- `dist/x86_64/tmux` — plain name
- `dist/x86_64/tmux-next-3.7-<rev>-linux-x86_64-static` — versioned (released)

`riscv64` builds run under QEMU emulation. The wrapper registers the binfmt
handler for you via a one-shot `docker run --privileged tonistiigi/binfmt` — it
installs no packages and resets on reboot. `x86_64` needs nothing.

### Mirrors (local only)

Local builds default to CN mirrors for speed; **CI always uses upstream** (these are
only set for the local wrapper). Sources and their mirrors:

| source | upstream | local mirror |
|--------|----------|--------------|
| Alpine pkgs (incl. static libevent, rsync's zstd/lz4/openssl/acl) | dl-cdn.alpinelinux.org | `APK_MIRROR` = USTC |
| ncurses (GNU) | ftp.gnu.org | `GNU_MIRROR` = NJU |
| rsync (samba), xxHash (GitHub) | upstream | none exist — direct + retry (tiny files) |

Override or disable per build:
```sh
APK_MIRROR= GNU_MIRROR= ./build.sh tmux    # force all-upstream locally
```

## CI / Releases

`.github/workflows/build.yml`:

- **Auto-discovery** — the `discover` job scans `*/build.sh` and reads each tool's
  `ARCHES=` line to build the matrix. Adding a tool needs **no** workflow edits.
- **New version → one click** — *Actions → build-static → Run workflow*, choose a
  tool (or `all`) and a version (`latest` / `default` / explicit). It publishes a
  release tagged `<tool>-<version>` with the static binaries attached.
- **Cut a snapshot** — push a tag `v*` to build every tool at its `DEFAULT_VERSION`
  and release them under that tag. (tmux's default is master HEAD; the exact
  `next-3.7-<rev>` is recorded in each asset name and the release notes.)
- **Explicit versions** target one tool: `version=3.4.1` with `tool=all` is rejected.
- Every push / PR builds (and uploads artifacts) so breakage is caught early.

## Add a new tool

Create `mytool/build.sh` — that's the only file. Use an existing one as a template:

```sh
#!/bin/sh
set -eu
. "$(dirname "$0")/../_lib.sh"

TOOL=mytool
ARCHES="x86_64 riscv64"        # which arches CI/local build
DEFAULT_VERSION=1.2.3

latest_version() { gh_latest_tag owner/repo; }   # how to find the newest version

build_tool() {                 # runs inside Alpine; $RESOLVED_VERSION is set
  apk add --no-cache build-base wget tar file >/dev/null
  # ... download $RESOLVED_VERSION, configure with -static, make ...
  # ... run a smoke test ...
  BIN="$PWD/mytool"            # required: path to the built binary
  # BUILT_VERSION="..."        # optional: override the reported version
}

run_recipe
```

The harness (`_lib.sh`) handles the apk mirror, version resolution, static-link
verification, stripping, naming and `dist/` layout. CI picks it up automatically.

## Design notes

- **musl, not glibc**: glibc static binaries break on `getpwuid`/NSS (which tmux
  uses); static musl binaries are genuinely self-contained.
- **Local mirrors CI**: both run `./build.sh <tool> <arch> <version>`, so a green
  local build is a strong signal CI will pass. Two intentional differences: local
  defaults `APK_MIRROR` to USTC (CI forces upstream), and CI builds exactly each
  tool's declared `ARCHES` matrix.
- Each `build_tool` describes only what's tool-specific: deps, source, flags, smoke
  test. Everything else is shared.
