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
        _uv = UVListener.new(ip, port, this)
    }
    onConnect=(fn) {
        _onConnect = fn
    }
    serve() {
        _uv.listen_()
    }
    stop() {
        _uv.stop_()
    }
}

class Connection {
    construct new() {
        System.print("new connection")
        _uv = UVConnection.new(this)
    }
    writeLn(data) {
        _uv.write("%(data)\n")
    }
    uv_ { _uv }
    close() {
        _uv.close()
    }
}

#allocates= uv_tcp_tclient
foreign class UVConnection {
    construct new(connectionWren) {
        System.print("new UVconnection")
    }
    test() {
        System.print("UvConnection#test")
    }
    foreign write(str)
    foreign close()
}

foreign class UVListener {
    construct new(ip,port,serverWren) {

    }
    // binds and starts listening
    foreign listen_()
    // stops listening
    foreign stop_()
}