import Cocoa

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let field = CountdownTextField(frame: NSRect(x: 0, y: 0, width: 340, height: 78))
let large = NSFont.monospacedDigitSystemFont(ofSize: 62, weight: .semibold)
let small = NSFont.monospacedDigitSystemFont(ofSize: 46, weight: .semibold)
var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ name: String) {
    guard condition() else { fatalError("FAILED: \(name)") }
    checks += 1
}
func render(background: NSColor) -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 340, pixelsHigh: 78,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    background.setFill()
    field.bounds.fill()
    field.cell!.draw(withFrame: field.bounds, in: field)
    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}
func checkContrast(_ name: String) {
    // On white, white glyphs disappear without their dark edge; on black the
    // white fill must remain visible. These check the actual AppKit cell raster.
    let onWhite = render(background: .white)
    let onBlack = render(background: .black)
    var darkPixels = 0
    var brightPixels = 0
    for y in 0..<78 {
        for x in 0..<340 {
            let dark = onWhite.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
            let bright = onBlack.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
            if max(dark.redComponent, dark.greenComponent, dark.blueComponent) < 0.65 { darkPixels += 1 }
            if min(bright.redComponent, bright.greenComponent, bright.blueComponent) > 0.85 { brightPixels += 1 }
        }
    }
    check(darkPixels > 150, "\(name): visible dark edge on white")
    check(brightPixels > 150, "\(name): visible white fill on black")
}
field.update(text: "40:00", font: large, color: .white)
checkContrast("initial")
let initialValue = field.attributedStringValue
field.update(text: "40:00", font: large, color: .white)
check(field.attributedStringValue === initialValue, "unchanged timer tick avoids text invalidation")
let baseline = render(background: .white).representation(using: .png, properties: [:])!
for iteration in 0..<20 {
    field.update(text: "39:59", font: large, color: .white)
    field.update(text: "00:00", font: large, color: .systemOrange)
    // Exercise layout and layer changes that previously affected the shadow.
    field.wantsLayer = iteration % 2 == 0
    field.frame.size.width = 460
    field.update(text: "1234:00:00", font: small, color: .white)
    field.frame.size.width = 340
    field.update(text: "40:00", font: large, color: .white)
    checkContrast("reset \(iteration)")
    check(render(background: .white).representation(using: .png, properties: [:])! == baseline,
          "reset \(iteration): identical appearance after font/color/layer changes")
}
if CommandLine.arguments.count > 1 {
    let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    for (name, color) in [("white", NSColor.white), ("black", NSColor.black)] {
        try render(background: color).representation(using: .png, properties: [:])!
            .write(to: output.appendingPathComponent("outline-\(name).png"))
    }
}
print("Passed \(checks) text-rendering checks")
