import "socket" for TCPServer
import "timer" for Timer

class EchoClient {
  construct new(conn) {
    _conn = conn
  }
  handle() {
    _conn.writeLn("Hello, bob")
    var x 
    while (x = _conn.readLine()) {
        System.print(x)
        _conn.write(x)
    }
    // _conn.close()
  }
}

var server = TCPServer.new("127.0.0.1",7000)
server.onConnect = Fn.new() { |connection|
  System.print("onConnect fired")
  EchoClient.new(connection).handle()
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