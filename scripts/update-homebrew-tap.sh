#!/bin/bash
# Update homebrew-tap with version and SHA256.
# Usage: ./scripts/update-homebrew-tap.sh 1.6.2 <sha256> [tap_dir]
set -euo pipefail

VERSION="${1:?Usage: update-homebrew-tap.sh VERSION SHA256 [TAP_DIR]}"
SHA256="${2:?Usage: update-homebrew-tap.sh VERSION SHA256 [TAP_DIR]}"
TAP_DIR="${3:-/tmp/homebrew-tap}"
CASK_FILE="$TAP_DIR/Casks/bootayar.rb"

mkdir -p "$(dirname "$CASK_FILE")"
cat > "$CASK_FILE" <<CASK
cask "bootayar" do
  version "$VERSION"
  sha256 "$SHA256"

  url "https://github.com/themanoftalent/Bootayar/releases/download/v#{version}/Bootayar.dmg"
  name "Bootayar"
  desc "macOS Startup & Automation Manager — Manage startup apps, background services, and scheduled tasks."
  homepage "https://github.com/themanoftalent/Bootayar"

  app "Bootayar.app"

  zap trash: [
    "~/Library/Preferences/top.bootayar.Bootayar.plist",
    "~/Library/Application Support/Bootayar",
  ]
end
CASK

echo "✓ Wrote $CASK_FILE"
