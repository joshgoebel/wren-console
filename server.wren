import "socket" for TCPServer

var server = TCPServer.new("0.0.0.0",7000)
server.listen = Fn.new() { |connection|
    connection.writeLn("Hello, bob")
    connection.close()
}
server.serve()