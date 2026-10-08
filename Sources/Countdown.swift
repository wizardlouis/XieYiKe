import Foundation

struct Countdown {
    var duration: TimeInterval = 1200
    var remaining: TimeInterval = 1200
    var deadline: Date?
    mutating func start(at now: Date = Date()) {
        guard deadline == nil, remaining > 0 else { return }
        deadline = now.addingTimeInterval(remaining)
    }
    mutating func update(at now: Date = Date()) -> Bool {
        guard let end = deadline else { return false }
        remaining = max(0, end.timeIntervalSince(now))
        if remaining == 0 { deadline = nil; return true }
        return false
    }
    @discardableResult
    mutating func pause(at now: Date = Date()) -> Bool {
        let expired = update(at: now)
        deadline = nil
        return expired
    }
    mutating func reset() { deadline = nil; remaining = duration }
}

func formattedTime(_ remaining: TimeInterval, duration: TimeInterval) -> String {
    let seconds = Int(ceil(max(0, remaining)))
    func padded(_ value: Int) -> String { let s = String(value); return s.count < 2 ? "0" + s : s }
    if duration >= 3600 {
        return "\(padded(seconds / 3600)):\(padded((seconds / 60) % 60)):\(padded(seconds % 60))"
    }
    return "\(padded(seconds / 60)):\(padded(seconds % 60))"
}

func configuredDuration(hours: String, minutes: String, seconds: String) -> TimeInterval? {
    guard let h = Int(hours), let m = Int(minutes), let s = Int(seconds), h >= 0, (0...59).contains(m), (0...59).contains(s) else { return nil }
    let (base, overflow) = h.multipliedReportingOverflow(by: 3600)
    let (total, additionOverflow) = base.addingReportingOverflow(m * 60 + s)
    guard !overflow, !additionOverflow, total > 0, total < 9_007_199_254_740_000 else { return nil }
    return TimeInterval(total)
}

