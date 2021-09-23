// import "wren-package"
// import "essentials"
import "timer" for Timer
// //import "wren_essentials:essentials"

// import "json" for JSON


// import "enforce" for Enforce

// Enforce.string(3, "name")

import "io" for CStream, Stream, Stdout

// var s = Stream.new()

Stdout.print("hello")
Stdout.print("world")
Stdout.flush()

var stdin = CStream.openFD(0)
// stdin.handler=s
var s = Stream.fromCStream(stdin)

System.print("is terminal: %(s.isTerminal)" )

var t
while (t=s.read()) {
  System.print("Echo: %(t)")
}

// var io = CStream.openFD(1)
// io.write("booger\n")
// io.close()
// io.write("booger\n")

// io = null

Timer.sleep(500)
System.print("after timer")
