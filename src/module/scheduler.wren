class Scheduler {
  static boot() { __scheduled = [] }
  static add(callable) {
    if (callable is Fiber) {
      __scheduled.add(callable)
      return
    }
    __scheduled.add(Fiber.new {
      callable.call()
      runNextScheduled_()
    })
  }

  // Called by native code.
  static resume_(fiber) {  fiber.transfer() }
  static resume_(fiber, arg) { fiber.transfer(arg) }
  static resumeError_(fiber, error) { fiber.transferError(error) }

  static runNextScheduled_() {
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
