import Cocoa

/// Draw the original soft shadow with the glyphs, rather than relying on the lifetime of
/// NSTextField's backing layer when its text, color or font changes.
final class CountdownTextField: NSTextField {
    private var displayedText: String?
    private var displayedFont: NSFont?
    private var displayedColor: NSColor?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isEditable = false
        isSelectable = false
        isBordered = false
        drawsBackground = false
        alignment = .center
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func update(text: String, font: NSFont, color: NSColor) {
        guard displayedText != text || displayedFont != font || displayedColor != color else { return }
        displayedText = text
        displayedFont = font
        displayedColor = color
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.85)
        shadow.shadowBlurRadius = 4
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        let value = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color,
            .shadow: shadow,
            .paragraphStyle: paragraph
        ])
        // The timer polls at 10 Hz, but unchanged text needs no redraw.
        attributedStringValue = value
        needsDisplay = true
    }
}
