import "timer" for Timer
import "io" for Stdout
import "scheduler" for Scheduler

class Async {
  static waitForOthers() {
    Scheduler.add(Fiber.current)
    Fiber.suspend()
  }
  static run(callable) {
    Scheduler.add(callable)
    Scheduler.add(Fiber.current)
    Scheduler.runNextScheduled_()
  }
}

class Task {
    static run(fn) { Task.new(fn).run() }
    construct new(fn) {
        _fn = fn
    }
    isRunning { !_isDone }
    run() {
        Async.run {
            _fn.call()
            _isDone = true
        }
        return this
    }
    static await(list) {
        while(true) {
            // System.print(list.map { |task| !task.isRunning }.toList)
            if (list.any { |task| task.isRunning }) {
                Async.waitForOthers()
            } else {
                break
            }
        }
    }
}

var ONE_SECOND = 100

class Slow {
    construct new() {}
    loadFiles() {
        System.print("fetching files")
        Timer.sleep(ONE_SECOND * 5)
        System.print("files loaded")
    }
    loadGraphics() {
        System.print("fetching graphics")
        Timer.sleep(ONE_SECOND * 5)
        System.print("Graphics loaded")
    }
    time() {
        for (i in 0..10) {
            System.write(".")
            Stdout.flush()
            Timer.sleep(ONE_SECOND)
        }
    }
}

var s = Slow.new()
var a = Task.run { s.time() }
var b = Task.run { s.loadFiles() }
var c = Task.run { s.loadGraphics() }
Task.await([a,b,c])

System.print("done")
Stdout.flush()
// while(true) {
//     Timer.sleep(20)
// }
