import "socket" for TCPServer
import "timer" for Timer

var server = TCPServer.new("127.0.0.1",7000)
server.onConnect = Fn.new() { |connection|
    System.print("onConnect fired")
    connection.writeLn("Hello, bob")
    var x 
    while (x = connection.readWait()) {
        System.print(x)
        connection.write(x)
    }
    // connection.close()
}
server.serve()

// Timer.sleep(10000)
// System.print("stopping...")
// server.stop()

// Timer.sleep(10000)
// System.print("serving...")
// server.serve()
// server.stop()

// server = null
// System.gc()