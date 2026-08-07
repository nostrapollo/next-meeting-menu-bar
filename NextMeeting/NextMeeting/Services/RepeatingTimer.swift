import Foundation

/// Schedules repeating timers that do not keep their target alive.
///
/// A `Timer` retains its block and the run loop retains the timer, so a block
/// that captures its owner strongly keeps that owner alive for the life of the
/// process. Putting `[weak self]` on an inner `Task` does not help: the outer
/// block still captures `self` strongly in order to form that weak capture.
enum RepeatingTimer {

    /// - Parameter target: the timer's owner.
    /// - Returns: the scheduled timer, already added to `runLoop`.
    static func scheduled<Target: AnyObject>(
        every interval: TimeInterval,
        on runLoop: RunLoop = .main,
        target: Target,
        _ body: @escaping (Target) -> Void
    ) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: true) { [weak target] timer in
            guard let target else {
                timer.invalidate()
                return
            }

            body(target)
        }

        runLoop.add(timer, forMode: .common)
        return timer
    }
}
