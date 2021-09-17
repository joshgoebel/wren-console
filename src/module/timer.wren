import "scheduler" for Scheduler
import "enforce" for Enforce

class Timer {
  static sleep(milliseconds) {
    Enforce.positiveNum(milliseconds, "milliseconds")
    return Scheduler.await_ { startTimer_(milliseconds, Fiber.current) }
  }

  foreign static startTimer_(milliseconds, fiber)
}
