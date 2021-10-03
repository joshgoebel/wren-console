import "scheduler" for Scheduler

class NetworkErrorType {
  static ECONNREFUSED { "ECONNREFUSED" }
  static TYPES { { 
    61: NetworkErrorType.ECONNREFUSED
  } }
}

class NetworkError {
  construct new(message, errCode) {
    message = message
    error = errCode.abs
  }
  static fromCode(err) { new("", err) }
  error { _error }
  error=(e) { 
    _error = e
    if (NetworkErrorType.TYPES.containsKey(_error)) {
      _message = NetworkErrorType.TYPES[_error]
    }
  }
  message { _message }
  message=(m) { _message = m }
  toString { "NetworkError: %(message) (%(error))" }
  // TODO: change back to simple Fiber.abort when we're on wren-essentials
  raise() {
    System.print("ABORT: " + toString)
    Fiber.abort(this)
  }
}

// rough idea borrowed from Nim
class Lock {
  construct new() { _fiber = null }
  wait() { 
    _fiber = Fiber.current
    Scheduler.runNextScheduled_()
  }
  signal() { 
    if (_fiber == null) return

    var fb = _fiber
    _fiber = null
    Scheduler.resume_(fb) 
  }
  signal(v) { 
    if (_fiber == null) return

    var fb = _fiber
    _fiber = null
    Scheduler.resume_(fb, v) 
  }
}

class TCPServer {
    construct new(ip, port) {
        _ip = ip
        _port = port
        _uv = UVServer.new(ip, port)
        _uv.delegate = this
    }
    #delegated
    newIncomingConnection() {
      var uvconn = UVConnection.new()
      if (_uv.accept(uvconn)) {
        var connection = Connection.new(uvconn)
        onConnect.call(connection)
      } else {
        uvconn.close()
      }
    }
    onConnect=(fn) { _onConnect = fn }
    onConnect { _onConnect }
    serve() { _uv.listen() }
    stop() { _uv.stop() }
}

class Connection {
    static Open { "open" }
    static Closed { "closed" }

    construct new(uvconn) {
        _uv = uvconn
        _uv.delegate = this
        _readBuffer = ""
        _readLock = Lock.new()
        _status = Connection.Open
    }
    static connect(ip, port) {
      var conn = UVConnection.connect(ip,port)
      return Connection.new(conn)
    }
    // status
    isClosed { _status == Connection.Closed }
    isOpen { _status == Connection.Open }
    buffer_ { _readBuffer }
    uv_ { _uv }

    // output
    print(data) { _uv.write("%(data)\n") }
    write(data) { _uv.write(data) }
    writeBytes(strData) { _uv.writeBytes(strData) }

    // instantly returns the read buffer or null if there is nothing to read
    readImmediate() { 
        if (_readBuffer.isEmpty) return null 
        var result = _readBuffer
        _readBuffer = ""
        return result
    }
    // waits for data, then reads the entire buffer
    readAll() {
        if (_readBuffer.isEmpty) waitForData()
        return readImmediate()
    }

    // TODO: correct behavior when stream is closed?
    seek(bytes) {
      var data 
      if (bytes >= _readBuffer.count) {
        data = _readBuffer
        _readBuffer = ""
      } else {
        data = _readBuffer[0...bytes]
        _readBuffer = _readBuffer[bytes..-1]
      }
      return data
    }
    // TODO: correct behavior when stream is closed?
    readBytes(bytes) {
      while (isOpen && _readBuffer.count < bytes) {
        waitForData()
      }
      return seek(bytes)
    }
    readLine() {
      var lineSeparator
      while(true) {
        lineSeparator = _readBuffer.indexOf("\n")
        if (lineSeparator != -1) break
        // TODO: correct behavior when stream is closed?
        if (isClosed) return null
        waitForData()
      }
      var line = _readBuffer[0...lineSeparator]
      _readBuffer = _readBuffer[lineSeparator + 1..-1]
      return line
    }

    waitForData() { 
      if (isClosed) return

      _readLock.wait() 
    }

    // utility
    close() { 
        _uv.close() 
        _status = Connection.Closed
    }

    #delegated
    dataReceived(data) {
        if (data==null) { // eof
          _status = Connection.Closed
        } else {
          _readBuffer = _readBuffer + data
        }
        _readLock.signal()
    }
}



foreign class UVConnection {
    construct new() {}
    static connect(ip, port) {
      var result = Scheduler.await_ { connect_(ip,port) }
      if (result is UVConnection) return result

      NetworkError.fromCode(result).raise()
    }
    foreign static connect_(ip, port) 
    
    foreign writeBytes(strData)
    foreign write(str)
    foreign close()

    // delegates must provide:
    // - dataReceived
    foreign delegate=(d)
}

foreign class UVServer {
    construct new(ip,port) {}
    foreign accept(client)
    foreign listen()
    foreign stop()

    // delegates must provide:
    // - newIncomingConnection
    foreign delegate=(d)
}