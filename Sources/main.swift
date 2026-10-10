import Cocoa

final class OverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

func label(_ text: String, size: CGFloat = 14) -> NSTextField {
    let view = NSTextField(labelWithString: text)
    view.font = .systemFont(ofSize: size)
    return view
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuItemValidation {
    var clock = Countdown()
    var timer: Timer?
    var panel: OverlayPanel!
    var timeLabel: CountdownTextField!
    var startButton: NSButton!
    var controls: NSStackView!
    var unlockPanel: OverlayPanel!
    var isLocked = false
    var settings: NSWindow?
    var alerts: [NSPanel] = []
    var statusItem: NSStatusItem!
    let defaults = UserDefaults.standard
    var message = "时间到了，休息一下吧！"
    var fontSize: CGFloat = 64
    var messageColor = NSColor.systemOrange
    var hoursField: NSTextField!
    var minutesField: NSTextField!
    var secondsField: NSTextField!
    var messageField: NSTextField!
    var sizeField: NSTextField!
    var colorWell: NSColorWell!
    var errorLabel: NSTextField!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Preserve settings from the original locally distributed prototype.
        if defaults.object(forKey: "duration") == nil,
           let legacy = defaults.persistentDomain(forName: "com.local.floatingalarm") {
            for key in ["duration", "message", "fontSize", "color"] {
                if let value = legacy[key] { defaults.set(value, forKey: key) }
            }
        }
        let saved = defaults.double(forKey: "duration")
        clock.duration = saved.isFinite && saved > 0 && saved < 9_007_199_254_740_000 ? saved : 1200
        clock.reset()
        message = defaults.string(forKey: "message") ?? message
        let size = defaults.double(forKey: "fontSize")
        if size >= 12 && size <= 300 { fontSize = size }
        if let rgb = defaults.array(forKey: "color") as? [Double], rgb.count == 3 {
            messageColor = NSColor(srgbRed: rgb[0], green: rgb[1], blue: rgb[2], alpha: 1)
        }
        makeMenu()
        makeOverlay()
        let t = Timer(timeInterval: 0.1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(t, forMode: .common)
        timer = t
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(tick), name: NSWorkspace.didWakeNotification, object: nil)
    }

    func makeMenu() {
        let menu = NSMenu()
        for (title, selector) in [("显示倒计时", #selector(showOverlay)), ("开始", #selector(start)), ("暂停", #selector(pause)), ("重置", #selector(reset)), ("设置…", #selector(showSettings)), ("锁定／解锁", #selector(toggleLock)), ("关闭提醒", #selector(dismissAlerts))] {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let about = NSMenuItem(title: "关于歇一刻…", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
        let quit = NSMenuItem(title: "退出歇一刻", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        statusItem = NSStatusBar.system.statusItem(withLength: 30)
        if let button = statusItem.button {
            let configuration = NSImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            let icon = NSImage(systemSymbolName: "alarm.fill", accessibilityDescription: "歇一刻")?.withSymbolConfiguration(configuration)
            icon?.isTemplate = true
            button.image = icon
            button.imagePosition = .imageOnly
            button.title = ""
            button.setAccessibilityLabel("歇一刻")
        }
        statusItem.button?.toolTip = "歇一刻"
        statusItem.menu = menu
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        appItem.submenu = menu.copy() as? NSMenu
        let editItem = NSMenuItem(title: "编辑", action: nil, keyEquivalent: "")
        let edit = NSMenu(title: "编辑")
        for (title, action, key) in [("剪切", "cut:", "x"), ("复制", "copy:", "c"), ("粘贴", "paste:", "v"), ("全选", "selectAll:", "a")] {
            edit.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
        }
        editItem.submenu = edit
        mainMenu.addItem(editItem)
        NSApp.mainMenu = mainMenu
    }

    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "歇一刻 · XieYiKe",
            .credits: NSAttributedString(string: "透明、置顶的 Mac 倒计时工具。\nhttps://github.com/wizardlouis/XieYiKe")
        ])
    }

    func configureOverlay(_ window: NSPanel) {
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.isFloatingPanel = true
        window.isMovableByWindowBackground = true
    }

    func button(_ title: String, action: Selector) -> NSButton {
        let b = NSButton(title: title, target: self, action: action)
        b.bezelStyle = .rounded
        b.controlSize = .small
        b.font = .systemFont(ofSize: 12, weight: .medium)
        return b
    }

    func makeOverlay() {
        panel = OverlayPanel(contentRect: NSRect(x: 0, y: 0, width: 340, height: 116), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        configureOverlay(panel)
        panel.title = "歇一刻"
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 340, height: 116))
        panel.contentView = root
        startButton = iconButton("play.fill", title: "开始", action: #selector(toggleRunning))
        controls = NSStackView(views: [startButton, iconButton("arrow.counterclockwise", title: "重置", action: #selector(reset)), iconButton("gearshape", title: "设置", action: #selector(showSettings)), iconButton("lock.open", title: "锁定", action: #selector(toggleLock))])
        controls.orientation = .horizontal
        controls.spacing = 12
        controls.frame = NSRect(x: 96, y: 84, width: 148, height: 28)
        root.addSubview(controls)
        unlockPanel = OverlayPanel(contentRect: NSRect(x: 0, y: 0, width: 28, height: 28), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        configureOverlay(unlockPanel)
        unlockPanel.title = "解锁闹钟"
        unlockPanel.isMovableByWindowBackground = false
        let unlock = iconButton("lock.fill", title: "解锁", action: #selector(toggleLock))
        unlock.frame = NSRect(x: 0, y: 0, width: 28, height: 28)
        unlockPanel.contentView?.addSubview(unlock)
        panel.delegate = self
        timeLabel = CountdownTextField(frame: NSRect(x: 0, y: 2, width: 340, height: 78))
        root.addSubview(timeLabel)
        positionOverlay()
        showOverlay()
        refresh()
    }

    func positionOverlay() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: frame.midX - panel.frame.width / 2, y: frame.maxY - 122))
    }

    func iconButton(_ symbol: String, title: String, action: Selector) -> NSButton {
        let b = NSButton(image: NSImage(systemSymbolName: symbol, accessibilityDescription: title)!, target: self, action: action)
        b.isBordered = false
        b.imagePosition = .imageOnly
        b.imageScaling = .scaleProportionallyDown
        b.contentTintColor = NSColor(calibratedWhite: 0.46, alpha: 1)
        b.toolTip = title
        b.setAccessibilityLabel(title)
        b.wantsLayer = true
        b.layer?.shadowColor = NSColor.white.cgColor
        b.layer?.shadowOpacity = 0.5
        b.layer?.shadowRadius = 2
        b.layer?.shadowOffset = CGSize(width: 0, height: -1)
        b.widthAnchor.constraint(equalToConstant: 28).isActive = true
        b.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return b
    }
    func positionUnlock() {
        unlockPanel.setFrameOrigin(NSPoint(x: panel.frame.midX - 14, y: panel.frame.minY + 84))
    }
    func windowDidMove(_ notification: Notification) { if isLocked { positionUnlock() } }
    @objc func toggleLock() {
        isLocked.toggle()
        controls.isHidden = isLocked
        panel.isMovableByWindowBackground = !isLocked
        panel.ignoresMouseEvents = isLocked
        if isLocked {
            settings?.close(); settings = nil
            positionUnlock()
            panel.addChildWindow(unlockPanel, ordered: .above)
            unlockPanel.makeKeyAndOrderFront(nil)
        } else {
            panel.removeChildWindow(unlockPanel)
            unlockPanel.orderOut(nil)
        }
    }
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if [#selector(start), #selector(pause), #selector(reset), #selector(showSettings)].contains(menuItem.action) { return !isLocked }
        return true
    }
    @objc func toggleRunning() { if clock.deadline == nil { start() } else { pause() } }
    @objc func showOverlay() { panel.orderFrontRegardless(); if isLocked { unlockPanel.orderFrontRegardless() } }
    @objc func start() { guard !isLocked else { return }; dismissAlerts(); clock.start(); refresh() }
    @objc func pause() {
        guard !isLocked else { return }
        if clock.pause() { showAlerts() }
        refresh()
    }
    @objc func reset() { guard !isLocked else { return }; dismissAlerts(); clock.reset(); refresh() }
    @objc func tick() {
        if clock.update() { showAlerts() }
        refresh()
    }
    func refresh() {
        let seconds = Int(ceil(clock.remaining))
        let text = formattedTime(clock.remaining, duration: clock.duration)
        let font = NSFont.monospacedDigitSystemFont(ofSize: clock.duration >= 3600 ? 46 : 62, weight: .semibold)
        let neededWidth = max(340, ceil((formattedTime(clock.duration, duration: clock.duration) as NSString).size(withAttributes: [.font: font]).width) + 32)
        let maxWidth = (panel.screen ?? NSScreen.main)?.visibleFrame.width ?? 1000
        let width = min(neededWidth, maxWidth)
        let fittedFont = NSFont.monospacedDigitSystemFont(ofSize: font.pointSize * min(1, (width - 32) / (neededWidth - 32)), weight: .semibold)
        if panel.frame.width != width {
            var frame = panel.frame
            frame.origin.x -= (width - frame.width) / 2
            frame.size.width = width
            panel.setFrame(frame, display: true)
            timeLabel.frame.size.width = width
            controls.frame.origin.x = (width - controls.frame.width) / 2
            if isLocked { positionUnlock() }
        }
        timeLabel.update(text: text, font: fittedFont, color: seconds == 0 ? .systemOrange : .white)
        let running = clock.deadline != nil
        let title = running ? "暂停" : "开始"
        startButton.image = NSImage(systemSymbolName: running ? "pause.fill" : "play.fill", accessibilityDescription: title)
        startButton.toolTip = title
        startButton.setAccessibilityLabel(title)
        startButton.isEnabled = seconds > 0
    }

    @objc func showSettings() {
        guard !isLocked else { return }
        if let window = settings { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 345), styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "歇一刻 · 设置"
        window.isReleasedWhenClosed = false
        window.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 2)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        let root = window.contentView!
        func addLabel(_ text: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat) {
            let l = label(text); l.frame = NSRect(x: x, y: y, width: width, height: 24); root.addSubview(l)
        }
        func field(_ text: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat) -> NSTextField {
            let f = NSTextField(string: text); f.frame = NSRect(x: x, y: y, width: width, height: 26); root.addSubview(f); return f
        }
        addLabel("倒计时时长", 24, 291, 110)
        hoursField = field(String(Int(clock.duration) / 3600), 128, 291, 100)
        addLabel("时", 232, 291, 24)
        minutesField = field(String((Int(clock.duration) / 60) % 60), 264, 291, 58)
        addLabel("分", 326, 291, 24)
        secondsField = field(String(Int(clock.duration) % 60), 358, 291, 58)
        addLabel("秒", 420, 291, 30)
        addLabel("到时提醒文字", 24, 239, 200)
        messageField = field(message, 24, 202, 432)
        addLabel("字体大小", 24, 153, 110)
        sizeField = field(String(Int(fontSize)), 140, 153, 86)
        addLabel("pt（12–300）", 236, 153, 130)
        addLabel("文字颜色", 24, 107, 110)
        colorWell = NSColorWell(frame: NSRect(x: 140, y: 104, width: 86, height: 30))
        colorWell.color = messageColor
        root.addSubview(colorWell)
        errorLabel = label("保存时长后，倒计时会重置。", size: 12)
        errorLabel.frame = NSRect(x: 24, y: 64, width: 432, height: 24)
        errorLabel.textColor = .secondaryLabelColor
        root.addSubview(errorLabel)
        let preview = button("预览提醒", action: #selector(previewAlert))
        preview.frame = NSRect(x: 24, y: 19, width: 105, height: 30)
        root.addSubview(preview)
        let save = button("保存", action: #selector(saveSettings))
        save.frame = NSRect(x: 350, y: 19, width: 106, height: 30)
        save.keyEquivalent = "\r"
        root.addSubview(save)
        settings = window
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func readSettings() -> (TimeInterval, String, CGFloat, NSColor)? {
        guard let duration = configuredDuration(hours: hoursField.stringValue, minutes: minutesField.stringValue, seconds: secondsField.stringValue), let size = Double(sizeField.stringValue), size.isFinite, size >= 12, size <= 300, !messageField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorLabel.stringValue = "时长需大于零，分秒为 0–59；文字非空，字号 12–300。"
            errorLabel.textColor = .systemRed
            return nil
        }
        return (duration, messageField.stringValue, CGFloat(size), colorWell.color)
    }
    @objc func saveSettings() {
        guard let (duration, text, size, color) = readSettings() else { return }
        let changed = clock.duration != duration
        clock.duration = duration; message = text; fontSize = size; messageColor = color
        defaults.set(duration, forKey: "duration")
        defaults.set(text, forKey: "message")
        defaults.set(size, forKey: "fontSize")
        let rgb = color.usingColorSpace(.sRGB) ?? .systemOrange
        defaults.set([rgb.redComponent, rgb.greenComponent, rgb.blueComponent], forKey: "color")
        if changed { reset() }
        settings?.close(); settings = nil
    }
    @objc func previewAlert() {
        guard let (_, text, size, color) = readSettings() else { return }
        showAlerts(text: text, size: size, color: color)
    }
    func showAlerts() { showAlerts(text: message, size: fontSize, color: messageColor) }
    func showAlerts(text: String, size: CGFloat, color: NSColor) {
        dismissAlerts()
        for screen in NSScreen.screens {
            let frame = screen.frame
            let width = max(200, frame.width - 100)
            let textView = NSTextView(frame: .zero)
            textView.isEditable = false; textView.isSelectable = false
            textView.drawsBackground = false
            textView.textContainerInset = NSSize(width: 10, height: 10)
            let paragraph = NSMutableParagraphStyle(); paragraph.alignment = .center
            let shadow = NSShadow(); shadow.shadowColor = NSColor.black.withAlphaComponent(0.9); shadow.shadowBlurRadius = 5; shadow.shadowOffset = NSSize(width: 0, height: -1)
            let attributed = NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: size, weight: .semibold), .foregroundColor: color, .paragraphStyle: paragraph, .shadow: shadow])
            textView.textStorage?.setAttributedString(attributed)
            textView.textContainer?.containerSize = NSSize(width: width - 20, height: CGFloat.greatestFiniteMagnitude)
            textView.textContainer?.widthTracksTextView = false
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
            let height = min(frame.height - 150, ceil(textView.layoutManager!.usedRect(for: textView.textContainer!).height) + 30)
            let window = OverlayPanel(contentRect: NSRect(x: frame.midX - width / 2, y: frame.midY - height / 2 - 45, width: width, height: height + 45), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            configureOverlay(window)
            window.title = "到时提醒"
            window.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 3)
            window.isMovableByWindowBackground = false
            let scroll = NSScrollView(frame: NSRect(x: 0, y: 45, width: width, height: height))
            scroll.drawsBackground = false; scroll.hasVerticalScroller = true
            textView.frame = NSRect(x: 0, y: 0, width: width, height: max(height, ceil(textView.layoutManager!.usedRect(for: textView.textContainer!).height) + 30))
            scroll.documentView = textView
            window.contentView?.addSubview(scroll)
            let dismiss = button("关闭提醒（所有屏幕）", action: #selector(dismissAlerts))
            dismiss.frame = NSRect(x: width / 2 - 100, y: 5, width: 200, height: 30)
            window.contentView?.addSubview(dismiss)
            alerts.append(window)
            window.orderFrontRegardless()
        }
        alerts.first?.makeKeyAndOrderFront(nil)
    }
    @objc func dismissAlerts() { for window in alerts { window.close() }; alerts.removeAll() }
    @objc func screensChanged() {
        if !NSScreen.screens.contains(where: { $0.visibleFrame.intersects(panel.frame) }) { positionOverlay() }
        if !alerts.isEmpty { showAlerts() }
        showOverlay()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
