#!/bin/bash
# Build the portable OpenCode engine from the opencode-main source tree.
# Usage:
#   ./tools/build_engine.sh
#   OPENCODE_SRC=/path/to/opencode-main ./tools/build_engine.sh
#   TARGETS="linux/amd64 windows/amd64" ./tools/build_engine.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${OPENCODE_SRC:-$ROOT_DIR/../opencode-main}"
OUT_DIR="$ROOT_DIR/engine"
VERSION="${VERSION:-v0.0.55-portable}"
TARGETS="${TARGETS:-linux/amd64 linux/arm64 windows/amd64 darwin/arm64 darwin/amd64}"

if [ ! -d "$SRC_DIR" ]; then
    echo "[ERROR] Source tree not found: $SRC_DIR"
    echo "        Set OPENCODE_SRC to the opencode-main directory."
    exit 1
fi

if ! command -v go >/dev/null 2>&1; then
    echo "[ERROR] Go toolchain not found in PATH (need Go 1.24 or newer)."
    echo "        Download it from https://go.dev/dl/ and try again."
    exit 1
fi

echo "[~] Source : $SRC_DIR"
echo "[~] Engine : $OUT_DIR"
echo "[~] Version: $VERSION"
echo ""

for target in $TARGETS; do
    os="${target%/*}"
    arch="${target#*/}"
    dir_arch="$arch"
    [ "$arch" = "amd64" ] && dir_arch="x64"

    out_dir="$OUT_DIR/opencode-$os-$dir_arch"
    out="$out_dir/opencode"
    [ "$os" = "windows" ] && out="$out.exe"

    mkdir -p "$out_dir"
    echo ">> $os/$arch -> $out"
    (
        cd "$SRC_DIR"
        CGO_ENABLED=0 GOOS="$os" GOARCH="$arch" go build \
            -trimpath \
            -ldflags "-s -w -X github.com/opencode-ai/opencode/internal/version.Version=$VERSION" \
            -o "$out" .
    )
done

echo ""
echo "[OK] Engine builds ready under $OUT_DIR"
