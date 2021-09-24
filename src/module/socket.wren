import "scheduler" for Scheduler

class Socket {
}

// foreign class TCPServer is Base {
//     construct new(ip, port) {
//             _ip = ip
//             _port = port
//         }
//     listen=(handler) {
//         _handler = handler
//     }
//     serve() {
//         serve_(_ip,_port)
//     }

//     foreign serve_(ip,port)
// }

class TCPServer {
    construct new(ip, port) {
        _ip = ip
        _port = port
        _connections = []
        _uv = UVServer.new(ip, port, this)
        _uv.connectionCB = Fn.new {
          var uvconn = UVConnection.new()
          if (_uv.accept(uvconn)) {
            var connection = Connection.new(uvconn)
            _connections.add(connection)
            onConnect.call(connection)
          } else {
            uvconn.close()
          }
        }
    }
    onConnect=(fn) { _onConnect = fn }
    onConnect { _onConnect }
    serve() { _uv.listen_() }
    stop() { _uv.stop_() }
}

class Connection {
    construct new(uvconn) {
        System.print("new connection")
        // _uv = UVConnection.new(this)
        _uv = uvconn
        _readBuffer = ""
        _isClosed = false
    }
    isClosed { _isClosed }
    writeLn(data) { _uv.write("%(data)\n") }
    write(data) { _uv.write("%(data)") }
    uv_ { _uv }
    close() { 
        _uv.close() 
        _isClosed = true
    }
    // instantly returns the read buffer or null if there is nothing to read
    read() { 
        if (_readBuffer.isEmpty) return null 
        var result = _readBuffer
        _readBuffer = ""
        return result
    }
    // reads data and waits to it if there isn't any
    readWait() {
        if (_readBuffer.isEmpty) {
            _sleepingForRead = Fiber.current
            Scheduler.runNextScheduled_()
        }
        return read()
    }

    // called by C
    input_(data) {
        System.print(("input_"))
        _readBuffer = _readBuffer + data
        if (_sleepingForRead) { 
            var fiber = _sleepingForRead    
            _sleepingForRead = null
            Scheduler.resume_(fiber) 
        }
    }
}

#allocates= uv_tcp_tclient
foreign class UVConnection {
    construct new() {}
    construct new(connectionWren) {
        System.print("new UVconnection")
    }
    foreign write(str)
    foreign close()
}

foreign class UVServer {
    construct new(ip,port,serverWren) {

    }
    // binds and starts listening
    foreign listen_()
    // stops listening
    foreign stop_()
}