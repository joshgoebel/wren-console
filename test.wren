// import "wren-package"
// import "essentials"
import "timer" for Timer
// //import "wren_essentials:essentials"

// import "json" for JSON


// import "enforce" for Enforce

// Enforce.string(3, "name")

import "io" for CStream, Stream, Stdout, Stderr

// var s = Stream.new()

Stdout.print("hello world")
Stdout.flush()

// Stderr.print("ERROR")

var stdin = CStream.openFD(0)
var s = Stream.fromCStream(stdin)

System.print("is terminal: %(s.isTerminal)" )
System.print("stdout descriptor: %(Stdout.descriptor)" )

var t
while (t=s.readLine()) {
  System.print("Echo: `%(t)`")
}

// var io = CStream.openFD(1)
// io.write("booger\n")
// io.close()
// io.write("booger\n")

// io = null

Timer.sleep(500)
System.print("after timer")
