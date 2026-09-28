# liquid_glass_easy vs Apple Liquid Glass

Apple's real Liquid Glass (a SwiftUI app on the iOS 26 Simulator) next to
[liquid_glass_easy](https://github.com/AhmeedGamil/liquid_glass_easy) (a
Flutter app), on the same scenes, with the same backgrounds, driven by the
same gesture script. Runs on GitHub's free macOS runners, so no Mac needed.

| Scene   | Apple                                        | Package                          |
|---------|----------------------------------------------|----------------------------------|
| glass   | `.glassEffect(.regular / .clear)`            | `LiquidGlassLens`                |
| buttons | `.glassEffect(.interactive())`, `.glass`, `.glassProminent` | `LiquidGlassButton` |
| slider  | `Slider`                                     | `LiquidGlassSlider`              |
| toggle  | `Toggle`                                     | `LiquidGlassSwitch`              |
| tabbar  | `TabView`                                    | `LiquidGlassScaffold` + `LiquidGlassTabBar` |

## Run it

Actions → **Compare** → Run workflow.

- **record**: runs every scene in both apps, records the simulator screen,
  and publishes the compare page to GitHub Pages (side by side, wipe, flip,
  frame stepping, slow motion). Clips are also attached to the run.
- **live**: keeps a Mac with both apps installed up for `live_minutes`,
  reachable over Tailscale with any VNC viewer at `lg-compare-mac:5900`.
  Cancel the run to shut it down early.
- **both**: the two at once, on two runners.

`package_ref` picks the branch, tag or commit of the package to compare.

## One-time setup for live mode

Repository secrets:

- `TS_AUTHKEY`: a Tailscale auth key (reusable + ephemeral).
- `VNC_PASSWORD`: the VNC password (the first 8 characters are what
  classic VNC viewers use).

## Layout

- `apple/`: the SwiftUI reference app + the UI-test gesture scripts
  (XcodeGen `project.yml`).
- `package_app/`: the Flutter app. `lib/layout.dart` holds the styles
  standing in for Apple's `.regular` / `.clear`, the knobs to tune.
- `tools/record.py`: records one app and writes the scene marks.
- `site/index.html`: the compare page.

Positions are shared by `apple/AppleReference/Layout.swift`,
`package_app/lib/layout.dart` and `apple/CompareUITests/SceneTests.swift`;
change them together.
