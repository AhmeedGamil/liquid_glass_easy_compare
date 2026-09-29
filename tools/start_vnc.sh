#!/bin/bash
# Turns on macOS Screen Sharing for the runner session, with $VNC_PASSWORD
# as both the classic VNC password (first 8 characters) and the runner
# user's login password, so any VNC viewer can get in.
set -u
KICK=/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart

# dscl alone is refused for a user holding a SecureToken, so reset through
# sysadminctl too, then check the Mac really takes the new password.
sudo sysadminctl -resetPasswordFor runner -newPassword "$VNC_PASSWORD" 2>&1 | tail -2 || true
sudo dscl . -passwd /Users/runner "$VNC_PASSWORD" 2>&1 || true
if dscl . -authonly runner "$VNC_PASSWORD" 2>/dev/null; then
  echo "runner login password set"
else
  echo "::warning::the runner login password did not change"
fi

# Keep the session from ever locking or sleeping, so no password is asked.
sudo sysadminctl -screenLock off -password "$VNC_PASSWORD" 2>&1 || true
defaults write com.apple.screensaver askForPassword -int 0
defaults write com.apple.screensaver askForPasswordDelay -int 0
defaults -currentHost write com.apple.screensaver idleTime -int 0
sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime -int 0
sudo pmset -a displaysleep 0 sleep 0 disksleep 0 2>/dev/null || true

# The classic VNC password is stored XOR'd with a fixed key.
echo "$VNC_PASSWORD" | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA" }; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' \
  | sudo tee /Library/Preferences/com.apple.VNCSettings.txt >/dev/null

# Without Screen Recording permission macOS sends viewers a black screen
# with only the cursor. The runner image leaves the system TCC database
# writable, so grant it (and input control) to the screen sharing agents.
csrutil status || true
TCC="/Library/Application Support/com.apple.TCC/TCC.db"
NOW=$(date +%s)
COLS=$(sudo sqlite3 "$TCC" "PRAGMA table_info(access);" | cut -d'|' -f2 | paste -sd' ' -)
echo "TCC access columns: $COLS"
grant() { # service client client_type
  sudo sqlite3 "$TCC" "INSERT OR REPLACE INTO access (service, client, client_type, auth_value, auth_reason, auth_version, flags, last_modified) VALUES ('$1', '$2', $3, 2, 4, 1, 0, $NOW);" \
    && echo "granted $1 to $2" || echo "::warning::could not grant $1 to $2"
}
for SERVICE in kTCCServiceScreenCapture kTCCServicePostEvent kTCCServiceAccessibility kTCCServiceListenEvent; do
  grant "$SERVICE" com.apple.screensharing.agent 0
  grant "$SERVICE" com.apple.RemoteDesktopAgent 0
  grant "$SERVICE" com.apple.screensharing 0
  grant "$SERVICE" /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/MacOS/ARDAgent 1
  grant "$SERVICE" /System/Library/CoreServices/RemoteManagement/screensharingd.bundle/Contents/MacOS/screensharingd 1
  grant "$SERVICE" /System/Library/CoreServices/RemoteManagement/ScreensharingAgent.bundle/Contents/MacOS/ScreensharingAgent 1
done
sudo sqlite3 "$TCC" "SELECT service, client, auth_value FROM access WHERE client LIKE '%creen%' OR client LIKE '%RemoteDesktop%' OR client LIKE '%ARD%';" || true
sudo killall -9 tccd 2>/dev/null || true

sudo "$KICK" -configure -allowAccessFor -allUsers -privs -all
sudo "$KICK" -configure -clientopts -setvnclegacy -vnclegacy yes
sudo "$KICK" -activate -restart -agent -console

# Screen Sharing proper, for viewers that speak Apple's own auth.
sudo defaults write /var/db/launchd.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false 2>/dev/null || true
sudo launchctl enable system/com.apple.screensharing 2>/dev/null || true
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true

# Restart the agents so they pick up the new permissions.
sudo killall screensharingd ScreensharingAgent ARDAgent 2>/dev/null || true
sleep 2
sudo "$KICK" -activate -restart -agent -console
sudo launchctl kickstart -k system/com.apple.screensharing 2>/dev/null || true

# Proof the display itself draws: a still of the whole screen for the run.
mkdir -p vnc-debug
screencapture -x vnc-debug/display.png 2>&1 || true

for _ in $(seq 1 20); do
  if sudo lsof -nP -iTCP:5900 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "VNC is listening on 5900"
    exit 0
  fi
  sleep 1
done
echo "::warning::nothing is listening on 5900 yet"
