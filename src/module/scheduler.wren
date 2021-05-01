class Scheduler {
  static boot() { __scheduled = [] }
  static add(callable) {
    __scheduled.add(Fiber.new {
      callable.call()
      runNextScheduled_()
    })
  }

  static waitForOthers() {
    __scheduled.add(Fiber.current)
    Fiber.suspend()
  }
  static runAsync(callable) {
    add(callable)
    __scheduled.add(Fiber.current)
    runNextScheduled_()
  }

  // Called by native code.
  static resume_(fiber) { 
    fiber.transfer() 
    }
  static resume_(fiber, arg) { fiber.transfer(arg) }
  static resumeError_(fiber, error) { fiber.transferError(error) }

  static runNextScheduled_() {
    // System.print("runNextScheduled_")
    if (__scheduled.isEmpty) {
      return Fiber.suspend()
    } else {
      return __scheduled.removeAt(0).transfer()
    }
  }

  foreign static captureMethods_()
}

Scheduler.boot()
Scheduler.captureMethods_()
