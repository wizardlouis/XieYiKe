import Cocoa

// Original vector artwork: a warm pause mark surrounded by a mint clock ring.
// No downloaded artwork, fonts, or third-party assets are embedded.
let out = CommandLine.arguments[1]
let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: rep)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
let bounds = NSRect(x: 70, y: 70, width: 884, height: 884)
let tile = NSBezierPath(roundedRect: bounds, xRadius: 202, yRadius: 202)
NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
shadow.shadowBlurRadius = 32
shadow.shadowOffset = NSSize(width: 0, height: -16)
shadow.set()
NSColor(calibratedRed: 0.055, green: 0.15, blue: 0.18, alpha: 1).setFill()
tile.fill()
NSGraphicsContext.restoreGraphicsState()
NSGradient(starting: NSColor(calibratedRed: 0.08, green: 0.30, blue: 0.32, alpha: 1), ending: NSColor(calibratedRed: 0.025, green: 0.11, blue: 0.16, alpha: 1))!.draw(in: tile, angle: -80)
NSColor.white.withAlphaComponent(0.15).setStroke()
tile.lineWidth = 3; tile.stroke()
let ring = NSBezierPath()
ring.appendArc(withCenter: NSPoint(x: 512, y: 512), radius: 267, startAngle: 65, endAngle: 395, clockwise: false)
ring.lineWidth = 43
ring.lineCapStyle = .round
NSColor(calibratedRed: 0.43, green: 0.91, blue: 0.78, alpha: 1).setStroke()
ring.stroke()
let tip = NSBezierPath(ovalIn: NSRect(x: 591, y: 746, width: 49, height: 49))
NSColor(calibratedRed: 1, green: 0.78, blue: 0.42, alpha: 1).setFill()
tip.fill()
for x in [414, 548] {
 let bar = NSBezierPath(roundedRect: NSRect(x: x, y: 391, width: 62, height: 242), xRadius: 31, yRadius: 31)
 NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.89, alpha: 1).setFill()
 bar.fill()
}
NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
