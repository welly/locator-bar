# Locator

A tiny macOS menu bar utility for amateur radio. The menu bar shows your current
Maidenhead locator (e.g. `IO91wm`). Clicking it shows:

- 8-character locator, coordinates, fix accuracy and fix time (UTC)
- CQ zone and ITU zone
- WAB (Worked All Britain) square: OS grid in Great Britain and the Isle of Man,
  Irish Grid in Ireland, UTM-based WA/WV squares in the Channel Islands
- Click the locator, coordinates, a zone or the WAB square to copy it
- Launch at Login (works once the app is installed, e.g. in `~/Applications`)
- About Locator

Everything is worked out on the Mac; your position is not sent anywhere.

## Download

Download `Locator-<version>.zip` from [Releases](https://github.com/welly/locator-bar/releases/latest), unzip it and move
**Locator.app** to Applications. It runs on Intel and Apple Silicon Macs with macOS 14 or later.

The app isn't notarised by Apple, so the first time you open it macOS will refuse. Go to **System Settings ›
Privacy & Security**, scroll down and click **Open Anyway** next to the message about Locator. (On macOS 14 you can
instead right-click the app and choose **Open**.)

## Build

Needs the Swift toolchain (Command Line Tools are enough), macOS 14+.

```sh
./scripts/build-app.sh            # builds build/Locator.app (universal)
./scripts/build-app.sh --install  # also copies it to ~/Applications
./scripts/build-app.sh --zip      # also makes build/Locator-<version>.zip for a release
```

On first launch macOS asks for Location access.

## Credits

CQ and ITU zone boundaries come from
[HB9HIL/hamradio-zones-geojson](https://github.com/HB9HIL/hamradio-zones-geojson) (MIT licence,
see `Resources/zones-LICENSE.txt`), reduced to `Resources/cqzones.json` and `Resources/ituzones.json`.

## Licence

MIT, see `LICENSE`.
