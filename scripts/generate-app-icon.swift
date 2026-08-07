#!/usr/bin/env swift

// Generates the macOS app icon from the same SF Symbol the menu bar uses
// ("calendar"), so the two can never drift apart.
//
//   swift scripts/generate-app-icon.swift
//
// Writes the ten PNG slots into Assets.xcassets/AppIcon.appiconset and
// rewrites its Contents.json. Every size is rendered natively from the vector
// symbol rather than downscaled from one master, so the 16pt slot stays crisp.

import AppKit
import Foundation

// MARK: - Design constants

/// The macOS icon grid: an 824x824 tile centred on a 1024x1024 canvas, with a
/// corner radius of 185. Expressed as ratios so every size renders identically.
let tileInsetRatio: CGFloat = 100.0 / 1024.0
let cornerRadiusRatio: CGFloat = 185.0 / 824.0
/// The glyph occupies just over half the tile, leaving the margin macOS icons
/// conventionally carry.
let glyphRatio: CGFloat = 0.56

let gradientTop = NSColor(srgbRed: 0x4A / 255.0, green: 0x8B / 255.0, blue: 0xF5 / 255.0, alpha: 1)
let gradientBottom = NSColor(srgbRed: 0x1B / 255.0, green: 0x4F / 255.0, blue: 0xC4 / 255.0, alpha: 1)
let glyphColor = NSColor.white

let symbolName = "calendar"

// MARK: - Contrast reporting
//
// The icon must read by brightness, not by hue, so the luminance separation is
// computed and printed rather than eyeballed.

func relativeLuminance(_ color: NSColor) -> Double {
    guard let srgb = color.usingColorSpace(.sRGB) else { return 0 }

    func channel(_ value: CGFloat) -> Double {
        let value = Double(value)
        return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }

    return 0.2126 * channel(srgb.redComponent)
        + 0.7152 * channel(srgb.greenComponent)
        + 0.0722 * channel(srgb.blueComponent)
}

func contrastRatio(_ lhs: NSColor, _ rhs: NSColor) -> Double {
    let first = relativeLuminance(lhs)
    let second = relativeLuminance(rhs)
    let lighter = max(first, second)
    let darker = min(first, second)
    return (lighter + 0.05) / (darker + 0.05)
}

// MARK: - Rendering

func aspectFitRect(_ size: NSSize, in bounds: NSRect) -> NSRect {
    guard size.width > 0, size.height > 0 else { return bounds }

    let scale = min(bounds.width / size.width, bounds.height / size.height)
    let fitted = NSSize(width: size.width * scale, height: size.height * scale)

    return NSRect(
        x: bounds.midX - fitted.width / 2,
        y: bounds.midY - fitted.height / 2,
        width: fitted.width,
        height: fitted.height
    )
}

/// The symbol drawn in `glyphColor` on a transparent canvas. Tinting happens
/// here, against transparency, so `.sourceAtop` touches only the glyph's own
/// pixels — doing it over the tile would flood the whole box with colour.
func makeGlyph(boxSize: NSSize) -> NSImage? {
    guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Calendar") else {
        return nil
    }

    let configuration = NSImage.SymbolConfiguration(pointSize: boxSize.height, weight: .regular)
    guard let configured = symbol.withSymbolConfiguration(configuration) else { return nil }

    let canvas = NSImage(size: boxSize)
    canvas.lockFocus()
    let drawRect = aspectFitRect(configured.size, in: NSRect(origin: .zero, size: boxSize))
    configured.draw(in: drawRect)
    glyphColor.set()
    drawRect.fill(using: .sourceAtop)
    canvas.unlockFocus()

    return canvas
}

func renderIcon(pixels: Int) -> Data? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let size = CGFloat(pixels)
    let inset = size * tileInsetRatio
    let tile = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = tile.width * cornerRadiusRatio

    let tilePath = NSBezierPath(roundedRect: tile, xRadius: radius, yRadius: radius)
    let gradient = NSGradient(starting: gradientBottom, ending: gradientTop)
    gradient?.draw(in: tilePath, angle: 90)

    let glyphBox = NSSize(width: tile.width * glyphRatio, height: tile.height * glyphRatio)
    if let glyph = makeGlyph(boxSize: glyphBox) {
        let target = NSRect(
            x: tile.midX - glyphBox.width / 2,
            y: tile.midY - glyphBox.height / 2,
            width: glyphBox.width,
            height: glyphBox.height
        )
        glyph.draw(in: target)
    }

    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])
}

// MARK: - Slots

struct Slot {
    let size: Int
    let scale: Int

    var pixels: Int { size * scale }
    var filename: String { scale == 1 ? "icon_\(size)x\(size).png" : "icon_\(size)x\(size)@\(scale)x.png" }
}

let slots = [16, 32, 128, 256, 512].flatMap { size in
    [Slot(size: size, scale: 1), Slot(size: size, scale: 2)]
}

// MARK: - Main

let repoRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconSet = repoRoot
    .appendingPathComponent("NextMeeting/NextMeeting/Assets.xcassets/AppIcon.appiconset")

guard FileManager.default.fileExists(atPath: iconSet.path) else {
    print("error: \(iconSet.path) not found — run this from the repository root")
    exit(1)
}

print("Glyph vs tile contrast (brightness separation, not hue):")
print(String(format: "  glyph luminance      %.4f", relativeLuminance(glyphColor)))
print(String(format: "  tile top luminance   %.4f", relativeLuminance(gradientTop)))
print(String(format: "  tile bottom lumin.   %.4f", relativeLuminance(gradientBottom)))
print(String(format: "  contrast vs top      %.2f:1", contrastRatio(glyphColor, gradientTop)))
print(String(format: "  contrast vs bottom   %.2f:1", contrastRatio(glyphColor, gradientBottom)))

let minimumContrast = 3.0
let worstContrast = min(contrastRatio(glyphColor, gradientTop), contrastRatio(glyphColor, gradientBottom))
guard worstContrast >= minimumContrast else {
    print(String(format: "error: worst contrast %.2f:1 is below the %.1f:1 minimum", worstContrast, minimumContrast))
    exit(1)
}

print("\nRendering \(slots.count) slots:")
for slot in slots {
    guard let data = renderIcon(pixels: slot.pixels) else {
        print("error: failed to render \(slot.filename)")
        exit(1)
    }

    let destination = iconSet.appendingPathComponent(slot.filename)
    do {
        try data.write(to: destination)
    } catch {
        print("error: failed to write \(slot.filename): \(error)")
        exit(1)
    }

    print("  \(slot.filename) (\(slot.pixels)px, \(data.count) bytes)")
}

let images = slots.map { slot in
    """
        {
          "filename" : "\(slot.filename)",
          "idiom" : "mac",
          "scale" : "\(slot.scale)x",
          "size" : "\(slot.size)x\(slot.size)"
        }
    """
}

let contents = """
{
  "images" : [
\(images.joined(separator: ",\n"))
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}

"""

do {
    try contents.write(to: iconSet.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
    print("\nRewrote Contents.json with \(slots.count) filename entries.")
} catch {
    print("error: failed to write Contents.json: \(error)")
    exit(1)
}
