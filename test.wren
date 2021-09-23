// import "wren-package"
// import "essentials"
import "timer" for Timer
// //import "wren_essentials:essentials"

// import "json" for JSON


// import "enforce" for Enforce

// Enforce.string(3, "name")

import "io" for CStream

var io = CStream.openFD(1)
io.write("booger\n")
io.close()
io.write("booger\n")

io = null

Timer.sleep(500)
