#!/usr/bin/env swift
// Package the maintained TinyTask icon master into macOS standard/Retina sizes.
// Creative source: Assets/TinyTaskIcon.png. Run from project root.
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let master = root.appendingPathComponent("Assets/TinyTaskIcon.png")
guard let image = NSImage(contentsOf: master) else { fatalError("Cannot read \(master.path)") }
let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]
let iconset = root.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for (name, size) in sizes {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { fatalError("Cannot allocate icon bitmap") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    // Normalize the device silhouette to the standard macOS Dock footprint.
    let side = CGFloat(size)
    image.draw(in: NSRect(x: side * 0.045, y: side * 0.045, width: side * 0.91, height: side * 0.91),
               from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("Cannot encode icon") }
    try png.write(to: iconset.appendingPathComponent(name))
    print("Generated \(name)")
}
