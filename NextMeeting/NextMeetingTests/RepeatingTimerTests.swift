import Foundation

private final class TickTarget {
    var ticks = 0
}

func runRepeatingTimerTests() {
    print("RepeatingTimer")

    TestRunner.test("fires the body with its target") {
        let target = TickTarget()
        let timer = RepeatingTimer.scheduled(every: 60, on: .current, target: target) { $0.ticks += 1 }
        defer { timer.invalidate() }

        timer.fire()
        timer.fire()

        TestRunner.expectEqual(target.ticks, 2)
    }

    // The run loop holds the timer and the timer holds its block, so a block
    // that captures the target strongly leaks it for the life of the process.
    TestRunner.test("does not keep its target alive") {
        weak var weakTarget: TickTarget?
        var timer: Timer?

        do {
            let target = TickTarget()
            weakTarget = target
            timer = RepeatingTimer.scheduled(every: 60, on: .current, target: target) { $0.ticks += 1 }
        }
        defer { timer?.invalidate() }

        TestRunner.expect(weakTarget == nil, "the timer must not retain its target")
    }

    TestRunner.test("invalidates itself once the target is gone") {
        weak var weakTarget: TickTarget?
        var timer: Timer?

        do {
            let target = TickTarget()
            weakTarget = target
            timer = RepeatingTimer.scheduled(every: 60, on: .current, target: target) { $0.ticks += 1 }
        }
        defer { timer?.invalidate() }

        TestRunner.expect(weakTarget == nil, "fixture: the target should already be deallocated")
        timer?.fire()

        TestRunner.expect(timer?.isValid == false, "a timer with no target left must stop itself")
    }
}
