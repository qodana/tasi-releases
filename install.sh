#!/bin/bash

set -e

RELEASE=${1}
TMP_DIR="/tmp/tasi-install"
OUT_DIR=${2:-"$HOME/.local/bin"}

# Remove trailing slashes
while [ "${OUT_DIR}" != "/" ] && [ "${OUT_DIR%/}" != "${OUT_DIR}" ]; do
  OUT_DIR="${OUT_DIR%/}"
done

echo "TASI Installer"
echo "=============="
echo "Installing to: $OUT_DIR/tasi"
echo ""

function cleanup {
  rm -rf "$TMP_DIR" > /dev/null 2>&1 || true
}

function fail {
  cleanup
  echo "Error: $1" >&2
  exit 1
}

trap cleanup EXIT

# Check bash
[ ! "$BASH_VERSION" ] && fail "Please use bash"

# Create output directory
mkdir -p "$OUT_DIR" 2>/dev/null || fail "Could not create output directory: $OUT_DIR"
[ -w "$OUT_DIR" ] || fail "Output directory is not writable: $OUT_DIR (try sudo or pass a writable directory as 2nd arg)"

# Check for curl or wget
GET=""
if which curl > /dev/null 2>&1; then
  GET="curl --fail -sL"
elif which wget > /dev/null 2>&1; then
  GET="wget -qO-"
else
  fail "Neither curl nor wget is installed"
fi

# Detect OS
case $(uname -s) in
  Darwin) OS="macos";;
  Linux) OS="linux";;
  *) fail "Unsupported OS: $(uname -s). Supported: macOS, Linux";;
esac

# Detect architecture
case $(uname -m) in
  x86_64) ARCH="amd64";;
  aarch64|arm64) ARCH="arm64";;
  *) fail "Unsupported architecture: $(uname -m). Supported: x86_64, arm64";;
esac

# Determine file to download
FILENAME=""
case "${OS}_${ARCH}" in
  "macos_arm64")
    FILENAME="tasi-macos-arm64.tar.gz"
    ;;
  "macos_amd64")
    # macOS Intel not built, try to use Rosetta
    echo "Warning: Intel Mac detected. Trying arm64 binary (will run under Rosetta)"
    FILENAME="tasi-macos-arm64.tar.gz"
    ;;
  "linux_amd64")
    FILENAME="tasi-linux-amd64.tar.gz"
    ;;
  "linux_arm64")
    # Linux ARM not built
    fail "Linux ARM64 is not supported. Only Linux x86_64 is available."
    ;;
  *) fail "No binary available for ${OS}_${ARCH}";;
esac

# Get latest release tag if not specified
if [ -z "$RELEASE" ]; then
  echo "Fetching latest release..."
  RELEASE=$(${GET} "https://api.github.com/repos/qodana/tasi-releases/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "")
  [ -z "$RELEASE" ] && fail "Could not determine latest release. Specify version as 1st argument."
fi

URL="https://github.com/qodana/tasi-releases/releases/download/${RELEASE}/${FILENAME}"

echo "Downloading TASI ${RELEASE}..."
echo "  URL: $URL"

# Download and extract
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

if ! ${GET} "$URL" | tar xzf - 2>/dev/null; then
  fail "Download or extraction failed. Check if release ${RELEASE} exists."
fi

# Find the binary (should be named 'tasi')
if [ ! -f "tasi" ]; then
  fail "Binary 'tasi' not found in archive"
fi

# Make executable
chmod +x tasi || fail "chmod +x failed"

# Remove quarantine attribute on macOS
if [ "$OS" = "macos" ]; then
  echo "Removing quarantine attribute..."
  xattr -d com.apple.quarantine tasi 2>/dev/null || true
fi

# Move to final location
mv tasi "$OUT_DIR/tasi" || fail "Failed to move binary to $OUT_DIR"

echo ""
echo "✓ TASI installed successfully!"
echo ""
echo "Location: $OUT_DIR/tasi"

# Check if directory is in PATH
case ":$PATH:" in
  *":$OUT_DIR:"*)
    echo ""
    echo "Run: tasi --help"
    ;;
  *)
    echo ""
    echo "⚠ $OUT_DIR is not in your PATH."
    echo "Add this line to your shell config (~/.zshrc, ~/.bashrc, ~/.profile):"
    echo "  export PATH=\"$OUT_DIR:\$PATH\""
    echo ""
    echo "Then restart your shell or run: source ~/.zshrc"
    echo ""
    echo "Or run directly: $OUT_DIR/tasi --help"
    ;;
esac

cleanup
