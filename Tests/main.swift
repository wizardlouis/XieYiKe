import Foundation

var checks = 0
func check(_ condition: @autoclosure () -> Bool, _ label: String) {
    guard condition() else { fatalError("FAILED: \(label)") }
    checks += 1
}
let now = Date(timeIntervalSince1970: 1_700_000_000)
var c = Countdown()
c.start(at: now)
check(!c.update(at: now.addingTimeInterval(10)), "running before deadline")
check(c.remaining == 1190, "elapsed time")
let originalDeadline = c.deadline
c.start(at: now.addingTimeInterval(20))
check(c.deadline == originalDeadline, "start is idempotent")
check(!c.pause(at: now.addingTimeInterval(20)), "pause before expiry")
check(c.remaining == 1180 && c.deadline == nil, "pause preserves remaining time")
check(!c.update(at: now.addingTimeInterval(200)), "paused clock stays paused")
check(c.remaining == 1180, "paused time is frozen")
c.start(at: now.addingTimeInterval(200))
check(c.deadline == now.addingTimeInterval(1380), "resume from remaining duration")
check(c.update(at: now.addingTimeInterval(1400)), "wake after deadline expires")
check(c.remaining == 0 && c.deadline == nil, "expiry clamps at zero")
check(!c.update(at: now.addingTimeInterval(1500)), "expiry emitted once")
c.start(at: now)
check(c.deadline == nil, "zero cannot restart without reset")
c.reset()
check(c.remaining == 1200 && c.deadline == nil, "reset restores duration")
c.duration = 3; c.reset(); c.start(at: now)
check(c.pause(at: now.addingTimeInterval(3)), "pausing at deadline still alerts")
check(formattedTime(3599, duration: 3599) == "59:59", "short format")
check(formattedTime(3600, duration: 3600) == "01:00:00", "exact hour")
check(formattedTime(3599, duration: 3600) == "00:59:59", "format remains stable")
check(formattedTime(1234 * 3600 + 62, duration: 1234 * 3600 + 62) == "1234:01:02", "four-digit hours")
check(formattedTime(0.1, duration: 20) == "00:01", "round partial second up")
check(configuredDuration(hours: "12345", minutes: "1", seconds: "2") == 44442062, "long duration")
check(configuredDuration(hours: "0", minutes: "0", seconds: "0") == nil, "reject zero")
check(configuredDuration(hours: "1", minutes: "60", seconds: "0") == nil, "reject invalid minutes")
check(configuredDuration(hours: "1", minutes: "0", seconds: "60") == nil, "reject invalid seconds")
check(configuredDuration(hours: "-1", minutes: "0", seconds: "0") == nil, "reject negative")
check(configuredDuration(hours: "hello", minutes: "0", seconds: "0") == nil, "reject nonnumeric")
check(configuredDuration(hours: String(Int.max), minutes: "0", seconds: "0") == nil, "reject overflow")
print("Passed \(checks) countdown checks")
