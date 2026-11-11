# Locator

A tiny macOS menu bar utility for amateur radio. The menu bar shows your current
Maidenhead locator (e.g. `IO91wm`). Clicking it shows:

- 8-character locator, coordinates, fix accuracy and fix time (UTC)
- CQ zone and ITU zone
- WAB (Worked All Britain) square: OS grid in Great Britain and the Isle of Man,
  Irish Grid in Ireland, UTM-based WA/WV squares in the Channel Islands
- Copy Locator / Copy Coordinates
- Launch at Login (works once the app is installed, e.g. in `~/Applications`)
- About Locator

Everything is worked out on the Mac; your position is not sent anywhere.

## Build

Needs the Swift toolchain (Command Line Tools are enough), macOS 14+.

```sh
./scripts/build-app.sh            # builds build/Locator.app
./scripts/build-app.sh --install  # also copies it to ~/Applications
```

On first launch macOS asks for Location access.

## Credits

CQ and ITU zone boundaries come from
[HB9HIL/hamradio-zones-geojson](https://github.com/HB9HIL/hamradio-zones-geojson) (MIT licence,
see `Resources/zones-LICENSE.txt`), reduced to `Resources/cqzones.json` and `Resources/ituzones.json`.
