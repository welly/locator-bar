// Draws the Locator app icon and writes Resources/AppIcon.icns.
// Run from the project root:  swift scripts/make-icon.swift
import AppKit

let size: CGFloat = 1024

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

func drawIcon(in ctx: CGContext) {
    // macOS icon grid: an 824pt rounded tile centred on the 1024 canvas.
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
    ctx.addPath(tilePath)
    ctx.setFillColor(color(0x0E3B44))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(tilePath)
    ctx.clip()

    // Map-teal tile with a soft top-to-bottom gradient.
    let bg = CGGradient(colorsSpace: srgb, colors: [color(0x2A8A80), color(0x0F3E48)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: tile.maxY), end: CGPoint(x: 0, y: tile.minY), options: [])

    // Maidenhead grid: squares centred so the pin lands in the middle of one.
    let cell: CGFloat = 275
    let gridX: [CGFloat] = [99.5, 374.5, 649.5, 924.5]
    let gridY: [CGFloat] = [25, 300, 575, 850]

    // The square you're in.
    let here = CGRect(x: gridX[1], y: gridY[1], width: cell, height: cell)
    ctx.setFillColor(color(0xF4B942, 0.9))
    ctx.fill(here)

    ctx.setStrokeColor(color(0xFFFFFF, 0.28))
    ctx.setLineWidth(8)
    for x in gridX {
        ctx.move(to: CGPoint(x: x, y: tile.minY))
        ctx.addLine(to: CGPoint(x: x, y: tile.maxY))
    }
    for y in gridY {
        ctx.move(to: CGPoint(x: tile.minX, y: y))
        ctx.addLine(to: CGPoint(x: tile.maxX, y: y))
    }
    ctx.strokePath()

    ctx.setStrokeColor(color(0xFFE2A0))
    ctx.setLineWidth(10)
    ctx.stroke(here.insetBy(dx: 5, dy: 5))

    // Shadow where the pin touches down.
    let tip = CGPoint(x: here.midX, y: here.minY + 75)
    ctx.setFillColor(color(0x000000, 0.28))
    ctx.fillEllipse(in: CGRect(x: tip.x - 50, y: tip.y - 16, width: 100, height: 32))
    ctx.restoreGState()

    // The pin: a teardrop whose point sits in the highlighted square.
    let r: CGFloat = 112
    let d: CGFloat = 190                              // tip to centre of the head
    let head = CGPoint(x: tip.x, y: tip.y + d)
    let phi = acos(r / d)                             // where the sides meet the head tangentially
    let pin = CGMutablePath()
    pin.move(to: tip)
    pin.addArc(center: head, radius: r, startAngle: -.pi / 2 + phi, endAngle: 3 * .pi / 2 - phi, clockwise: false)
    pin.closeSubpath()

    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: color(0x000000, 0.4))
    ctx.addPath(pin)
    ctx.setFillColor(color(0xD9452F))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(pin)
    ctx.clip()
    let pinShade = CGGradient(colorsSpace: srgb, colors: [color(0xF26A4B), color(0xB8341F)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(pinShade, start: CGPoint(x: head.x - r, y: head.y + r),
                           end: CGPoint(x: head.x + r, y: tip.y), options: [])
    ctx.restoreGState()

    // White centre of the pin head.
    let dot: CGFloat = 44
    ctx.setFillColor(color(0xFFFFFF))
    ctx.fillEllipse(in: CGRect(x: head.x - dot, y: head.y - dot, width: dot * 2, height: dot * 2))
}

func png(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let gc = NSGraphicsContext(bitmapImageRep: rep)!
    let ctx = gc.cgContext
    ctx.scaleBy(x: CGFloat(pixels) / size, y: CGFloat(pixels) / size)
    drawIcon(in: ctx)
    gc.flushGraphics()
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let iconset = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? fm.removeItem(at: iconset)
try! fm.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! png(pixels: base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! png(pixels: base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
try! png(pixels: 1024).write(to: URL(fileURLWithPath: "Resources/AppIcon-1024.png"))

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "Wrote Resources/AppIcon.icns" : "iconutil failed")
