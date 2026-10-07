// Renders the app icon (a rising probability line over a baseline, white on brand
// blue; the same design as the Android adaptive icon) for each Apple/Windows style.
//
// Usage: swift tool/render_icon.swift <ios|macos|windows> <out.png> [size]
//   ios      full-bleed opaque square; iOS applies its own corner mask. No alpha:
//            the App Store rejects transparent icons.
//   macos    Big Sur-style rounded square inset on a transparent canvas.
//   windows  rounded square, nearly full-size, transparent corners.
import AppKit
import CoreGraphics

let args = CommandLine.arguments
guard args.count >= 3, ["ios", "macos", "windows"].contains(args[1]) else {
  print("usage: swift tool/render_icon.swift <ios|macos|windows> <out.png> [size]")
  exit(1)
}
let style = args[1]
let out = args[2]
let size = args.count > 3 ? Int(args[3])! : 1024
let s = CGFloat(size)

let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: style == "ios" ? CGImageAlphaInfo.noneSkipLast.rawValue
                                               : CGImageAlphaInfo.premultipliedLast.rawValue)!
let brand = CGColor(srgbRed: 0x2D / 255, green: 0x6B / 255, blue: 0xEA / 255, alpha: 1)

// The tile: the whole canvas on iOS; a rounded square elsewhere.
let tile: CGRect
switch style {
case "macos": tile = CGRect(x: s * 0.098, y: s * 0.098, width: s * 0.804, height: s * 0.804) // Apple's 824/1024 grid
case "windows": tile = CGRect(x: s * 0.03, y: s * 0.03, width: s * 0.94, height: s * 0.94)
default: tile = CGRect(x: 0, y: 0, width: s, height: s)
}
if style == "ios" {
  ctx.setFillColor(brand)
  ctx.fill(tile)
} else {
  let path = CGPath(roundedRect: tile, cornerWidth: tile.width * 0.225, cornerHeight: tile.width * 0.225, transform: nil)
  if style == "macos" {
    // macOS icons carry a soft drop shadow under the tile.
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.01), blur: s * 0.03, color: CGColor(gray: 0, alpha: 0.3))
  }
  ctx.addPath(path)
  ctx.setFillColor(brand)
  ctx.fillPath()
  ctx.setShadow(offset: .zero, blur: 0, color: nil)
}

// Android vector coordinates are on a 108-unit canvas with y pointing down. Android crops
// adaptive icons to a central safe zone, so the artwork is scaled up around the tile's
// centre to fill it similarly.
let zoom: CGFloat = 1.35
let k = tile.width / 108 * zoom
func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
  CGPoint(x: tile.midX + (x - 54) * k, y: tile.midY - (y - 54) * k)
}

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
print("wrote \(out) (\(style), \(size)px)")
