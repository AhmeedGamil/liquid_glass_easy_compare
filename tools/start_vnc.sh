#!/bin/bash
# Turns on macOS Screen Sharing for the runner session, with $VNC_PASSWORD
# as both the classic VNC password (first 8 characters) and the runner
# user's login password, so any VNC viewer can get in.
set -u
KICK=/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart

sudo dscl . -passwd /Users/runner "$VNC_PASSWORD"

# The classic VNC password is stored XOR'd with a fixed key.
echo "$VNC_PASSWORD" | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA" }; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' \
  | sudo tee /Library/Preferences/com.apple.VNCSettings.txt >/dev/null

sudo "$KICK" -configure -allowAccessFor -allUsers -privs -all
sudo "$KICK" -configure -clientopts -setvnclegacy -vnclegacy yes
sudo "$KICK" -activate -restart -agent -console

# Screen Sharing proper, for viewers that speak Apple's own auth.
sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false 2>/dev/null || true
sudo launchctl enable system/com.apple.screensharing 2>/dev/null || true
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true

for _ in $(seq 1 20); do
  if sudo lsof -nP -iTCP:5900 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "VNC is listening on 5900"
    exit 0
  fi
  sleep 1
done
echo "::warning::nothing is listening on 5900 yet"
