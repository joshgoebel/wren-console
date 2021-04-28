import "socket" for TCPServer
import "timer" for Timer

var server = TCPServer.new("0.0.0.0",7000)
server.onConnect = Fn.new() { |connection|
    connection.writeLn("Hello, bob")
    connection.close()
}
server.serve()
Timer.sleep(2000)
System.print("stopping...")
server.stop()