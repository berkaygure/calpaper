#!/usr/bin/env swift

import AppKit

func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext

    // Background — dark rounded square
    let bgRect = NSRect(x: s * 0.05, y: s * 0.05, width: s * 0.9, height: s * 0.9)
    let bgRadius = s * 0.2
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: bgRadius, yRadius: bgRadius)
    NSColor(srgbRed: 0.118, green: 0.118, blue: 0.18, alpha: 1).setFill()
    bgPath.fill()

    // Curved divider (left section slightly lighter)
    let divPath = NSBezierPath()
    let splitX = s * 0.42
    let curve = s * 0.08
    divPath.move(to: NSPoint(x: s * 0.05, y: s * 0.05))
    divPath.line(to: NSPoint(x: s * 0.05, y: s * 0.95))
    // top edge
    let topLeftCorner = NSPoint(x: s * 0.05 + bgRadius, y: s * 0.95)
    divPath.appendArc(from: NSPoint(x: s * 0.05, y: s * 0.95), to: topLeftCorner, radius: bgRadius)
    divPath.line(to: NSPoint(x: splitX, y: s * 0.95))
    // curved edge going down
    divPath.curve(to: NSPoint(x: splitX, y: s * 0.05),
                  controlPoint1: NSPoint(x: splitX + curve, y: s * 0.7),
                  controlPoint2: NSPoint(x: splitX + curve, y: s * 0.3))
    divPath.close()

    // Clip to the rounded bg
    ctx.saveGState()
    bgPath.addClip()
    NSColor(srgbRed: 0.16, green: 0.16, blue: 0.22, alpha: 1).setFill()
    divPath.fill()
    ctx.restoreGState()

    // Draw dots grid (right side) — 3x3 grid
    let gridStartX = s * 0.52
    let gridStartY = s * 0.62
    let dotSpacing = s * 0.12
    let dotRadius = s * 0.035

    for row in 0..<3 {
        for col in 0..<3 {
            let cx = gridStartX + CGFloat(col) * dotSpacing
            let cy = gridStartY - CGFloat(row) * dotSpacing

            let dotColor: NSColor
            if row == 0 && col == 2 {
                // Today dot — highlight blue
                dotColor = NSColor(srgbRed: 0.537, green: 0.706, blue: 0.98, alpha: 1)
            } else if row == 2 || (row == 1 && col < 2) {
                // Past days — lighter
                dotColor = NSColor(srgbRed: 0.8, green: 0.84, blue: 0.96, alpha: 0.9)
            } else {
                // Future days — dim
                dotColor = NSColor(srgbRed: 0.42, green: 0.44, blue: 0.55, alpha: 0.7)
            }

            dotColor.setFill()
            let dotRect = NSRect(x: cx - dotRadius, y: cy - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
            NSBezierPath(ovalIn: dotRect).fill()
        }
    }

    // Draw "C" letter on left side (caption area)
    let font = NSFont(name: "Snell Roundhand", size: s * 0.3) ?? NSFont.systemFont(ofSize: s * 0.3, weight: .thin)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(srgbRed: 0.8, green: 0.84, blue: 0.96, alpha: 1)
    ]
    let str = NSAttributedString(string: "C", attributes: attrs)
    let strSize = str.size()
    let strX = s * 0.12
    let strY = (s - strSize.height) / 2
    str.draw(at: NSPoint(x: strX, y: strY))

    image.unlockFocus()
    return image
}

// Generate all required icon sizes
let iconSizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

for (size, filename) in iconSizes {
    let image = generateIcon(size: size)

    // Create a 1x bitmap rep at exact pixel dimensions to avoid Retina doubling
    let bitmapRep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    bitmapRep.size = NSSize(width: size, height: size)

    let context = NSGraphicsContext(bitmapImageRep: bitmapRep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to generate \(filename)")
        continue
    }

    let url = URL(fileURLWithPath: outputDir).appendingPathComponent(filename)
    try! pngData.write(to: url)
    print("Generated \(filename) (\(size)x\(size))")
}

print("Done!")
