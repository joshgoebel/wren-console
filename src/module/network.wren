import "scheduler" for Scheduler

class NetworkErrorType {
  static ECONNREFUSED { "ECONNREFUSED" }
  static TYPES { { 
    61: NetworkErrorType.ECONNREFUSED
  } }
}

class NetworkError {
  construct new(msg, errCode) {
    message = msg
    error = errCode.abs
  }
  static fromCode(err) { new("", err) }
  error { _error }
  error=(e) { 
    _error = e
    if (NetworkErrorType.TYPES.containsKey(_error)) {
      _message = _message + " " + NetworkErrorType.TYPES[_error]
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

class ErrorTuple {
  static raiseIfError(data) {
    if (!(data is List)) return
    if (!(data[0] is Num)) return

    NetworkError.new(data[1], data[0]).raise()
  }
}

class IPv4 {
  construct new() {
    _address = [0, 0, 0, 0]
  }
  construct fromString(s) {
    _address = s.split(".").map { |n| Num.fromString(n) }
  }
  isValid { _address.count == 4 && _address.all {|n| n is Num && n >= 0 && n <= 255 }}
  isIPv4 { isValid }
  isIPv6 { false }
  toString { _address.join(".") }
}

class DNS {
  static lookup(hostname) {
    var r = address_(hostname)
    ErrorTuple.raiseIfError(r)
    return r
  }
  foreign static address_(hostname) 
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
      var conn = UVConnection.connect(guaranteeIP(ip),port)
      return Connection.new(conn)
    }
    static guaranteeIP(host_or_ip) {
      var ip = IPv4.fromString(host_or_ip)
      if (ip.isValid) return host_or_ip

      return DNS.lookup(host_or_ip)
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
    //
    // if the connection closes then one of the two following `readAlls` will
    // return `null`, depending on if there was any data remaining in the buffer
    // to be read or not at the time of disconnect
    readAll() {
        if (_readBuffer.isEmpty) waitForData()
        return readImmediate()
    }

    // seek forward in the buffer by `bytes` bytes
    //
    // you can seek past the end, which will just leave the buffer empty. This
    // is intended to be used in combination with `_buffer` to implement custom
    // read functions in consumers.  Whether the connection is still open or not
    // makes no difference as `seek` is merely advancing the buffer
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

    // waits until `bytes` bytes of data are read from the connection
    //
    // - if the connection closes with no data read `null` is returned 
    // - if fewer bytes than requested are returned then also signals that the
    //   connection has closed
    readBytes(bytes) {
      while (isOpen && _readBuffer.count < bytes) {
        waitForData()
      }
      var data = seek(bytes)
      if (data=="" && isClosed) return null
      return data
    }
    readLine() {
      var lineSeparator
      while(true) {
        lineSeparator = _readBuffer.indexOf("\n")
        if (lineSeparator != -1) break
        // if the connection is closed `null` is returned and any data in the
        // buffer that doesn't constitue a full line is silently dropped
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

      // NetworkError.fromCode(result).raise()
      ErrorTuple.raiseIfError(result)
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