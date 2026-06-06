#!/usr/bin/env bash
# Build a static tool inside a throwaway Alpine container. Nothing is installed on
# the host -- only Docker is used. Cross-arch (riscv64) auto-registers a QEMU
# binfmt handler via a one-shot privileged container (ephemeral, no host packages).
#
#   ./build.sh <tool> [arch] [version]
#       arch:    x86_64 (default) | riscv64
#       version: (omit)=tool default | latest | explicit (e.g. 3.4.1 / 3.6b)
#
#   ./build.sh tmux
#   ./build.sh rsync x86_64 latest
#   ./build.sh rsync riscv64 3.4.1
#
# Env:
#   APK_MIRROR    apk mirror base (default: USTC). Set empty to use upstream (CI).
#   ALPINE_IMAGE  build image (default: alpine:3.22)
set -euo pipefail
cd "$(dirname "$0")"

TOOL="${1:-}"
ARCH="${2:-x86_64}"
VERSION_ARG="${3:-}"
ALPINE="${ALPINE_IMAGE:-alpine:3.22}"

[ -n "$TOOL" ] || { echo "usage: ./build.sh <tool> [x86_64|riscv64] [version]"; exit 2; }
[ -f "$TOOL/build.sh" ] || { echo "no such tool: $TOOL/build.sh"; exit 2; }

case "$ARCH" in
  x86_64|amd64) PLAT=linux/amd64;   ARCH=x86_64 ;;
  riscv64)      PLAT=linux/riscv64               ;;
  *) echo "unknown arch: $ARCH (use x86_64 or riscv64)"; exit 2 ;;
esac

# Enforce the tool's declared ARCHES -- same single source of truth CI's matrix uses.
TOOL_ARCHES=$(grep -E '^ARCHES=' "$TOOL/build.sh" | head -n1 \
  | sed -E "s/^ARCHES=//; s/[\"']//g; s/#.*//")
if [ -n "$TOOL_ARCHES" ]; then
  case " $TOOL_ARCHES " in
    *" $ARCH "*) ;;
    *) echo "arch '$ARCH' is not in ARCHES (\"$TOOL_ARCHES\") for $TOOL"; exit 2 ;;
  esac
fi

HOST_ARCH=$(uname -m)
if [ "$ARCH" != "$HOST_ARCH" ]; then
  echo "==> registering QEMU binfmt for $ARCH (ephemeral, container-only)"
  docker run --privileged --rm tonistiigi/binfmt --install "$ARCH" >/dev/null
fi

echo "==> building '$TOOL' for $ARCH (version=${VERSION_ARG:-default}) in $ALPINE"
# Pre-pull the base image with retries -- Docker Hub occasionally times out on CI runners.
for _n in 1 2 3 4 5; do
  docker pull --platform "$PLAT" "$ALPINE" && break
  echo "  base image pull failed, retry $_n ..."; sleep $((_n * 4))
done
docker run --rm --platform "$PLAT" \
  -e APK_MIRROR="${APK_MIRROR-https://mirrors.ustc.edu.cn/alpine}" \
  -e GNU_MIRROR="${GNU_MIRROR-https://mirror.nju.edu.cn/gnu}" \
  -e GOPROXY="${GOPROXY-https://goproxy.cn,direct}" \
  -e CARGO_MIRROR="${CARGO_MIRROR-sparse+https://mirrors.ustc.edu.cn/crates.io-index/}" \
  -e GH_API_TOKEN="${GH_API_TOKEN-}" \
  -e VERSION="${VERSION_ARG}" \
  -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
  -v "$PWD:/work" -w /work \
  "$ALPINE" sh "$TOOL/build.sh"

echo
echo "==> artifacts in dist/$ARCH/:"
ls -la "dist/$ARCH/"
