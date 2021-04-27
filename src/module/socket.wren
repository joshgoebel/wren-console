class Socket {
    
}

foreign class TCPServer {
    construct new(ip, port) {
            _ip = ip
            _port = port
        }
    listen=(handler) {
        _handler = handler
    }
    serve() {
        serve_(_ip,_port)
    }

    foreign serve_(ip,port)
}