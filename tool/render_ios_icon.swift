// Renders the 1024×1024 iOS app icon (same design as the Android adaptive icon:
// a rising probability line over a baseline, white on brand blue). No alpha — the
// App Store rejects transparent icons.
// Usage: swift tool/render_ios_icon.swift ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-1024.png
import AppKit
import CoreGraphics

let size = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Icon-1024.png"
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
// Android vector coordinates are on a 108-unit canvas with y pointing down. Android crops
// adaptive icons to a central safe zone, so the artwork is scaled up around the centre
// to fill iOS's full square similarly.
let zoom: CGFloat = 1.35
let k = CGFloat(size) / 108 * zoom
func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
  CGPoint(x: CGFloat(size) / 2 + (x - 54) * k, y: CGFloat(size) / 2 - (y - 54) * k)
}

ctx.setFillColor(CGColor(srgbRed: 0x2D / 255, green: 0x6B / 255, blue: 0xEA / 255, alpha: 1))
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.5))
ctx.setLineWidth(3 * k)
ctx.move(to: p(32, 76)); ctx.addLine(to: p(76, 76)); ctx.strokePath()

ctx.setStrokeColor(CGColor(gray: 1, alpha: 1))
ctx.setLineWidth(5 * k)
ctx.move(to: p(32, 68)); ctx.addLine(to: p(46, 56)); ctx.addLine(to: p(56, 62)); ctx.addLine(to: p(76, 40))
ctx.strokePath()
ctx.setFillColor(CGColor(gray: 1, alpha: 1))
ctx.fillEllipse(in: CGRect(origin: p(71, 45), size: CGSize(width: 10 * k, height: 10 * k)))

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("wrote \(out)")
