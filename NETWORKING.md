# Networking

Following is a proposal (and implementation) for a lightweight networking functionality for Wren CLI.  It's largely based on my more-Wren, less C philosophy.  I try to wrap the UVlib C API's as tightly/neatly as possible and then build higher-level abstractions on top of those low-level bindings for the actual library functionality.  I use the delegate pattern for handling C callbacks such that the C-side classes only have to keep track of a single handle back into Wren.

*Why?*

Cause without access to the internet... Obviously there are many other libraries one could link to if they wanted more "developed" network functionality - such as `libcurl` for downloads, etc.  The networking functionality here is bare-bones and intended for anyone wishing to build this stuff from foundations (`uvlib`, in console/CLI's case)

It seems there are all sorts of uses:

- lightweight HTTP server
- lightweight socket servers (telnet, MUD, etc)
- etc.

*Why am I posting it here?*

I'm hoping to get someone interested in contributing/helping or in building networking services in Wren (web stuff, MUD servers, etc).  Whether or not this ever lands in CLI officially I do plan to land in my own [wren-console](https://github.com/joshgoebel/wren-console) for sure.  I'm opening this PR against CLI because I started this work long before `wren-console` and `wren-essentials` even existed, and I haven't ported it over yet.  It probably makes the most sense in `wren-essentials` if it's not welcome here.

And I think it's a discussion worth having about what networking functionality in the CLI would look like.  It's also possible that one day this functionality could be provided by a [user defined native module](https://github.com/wren-lang/wren-cli/issues/52)...

## Overview

- `UVConnection` - low-level TCP connection
- `UVServer` - low-level TCP server
- `Connection` - high level connection management
- `TCPServer` - high level TCP server
- `DNS` - DNS utilities
- `NetworkError` - type of error Fibers abort with for network errors
- `AsyncHttpServer` - experimental, only half finished

---

### UVConnection (low-level API)

Wraps a `uv_stream_t` struct that represents a TCP connection.

```js
foreign class UVConnection {
    construct new() {}
    static connect(ip, port) // auto-async
    foreign writeBytes(strData)
    foreign write(str)
    foreign close()

    // delegates must provide:
    // - dataReceived
    foreign delegate=(d)
}
```

Establishes a TCP connection to the given IP and port.  A delegate object must be provided to handle `dataReceived` callbacks, example:

```js
class Connection {
    // ...
    dataReceived(data) {
        _readBuffer = _readBuffer + data
        // signal a waiting fiber that data was read
    }
}
```

In most cases the delegate will embed the lower-level class. See `Connection` for an example.  `Connection` simply wraps and serves as the delegate for `UVConnection`.


### UVServer (low-level API)

Wraps a `uv_tcp_t` struct and related socket listening functionality.

```js
foreign class UVServer {
    construct new(ip,port) {}
    foreign accept(client)
    foreign listen()
    foreign stop()

    // delegates must provide:
    // - newIncomingConnection
    foreign delegate=(d)
}
```

Creates a server listening on a given IP/port.  To accept new connections (much like the C API) `accept` must be called passing it a fresh `UVConnection`.  A boolean will be returned for whether the connection was accepted successfully or not. A delegate object must be provided to handle `newIncomingConnection` callbacks.

Example:

```js
    newIncomingConnection() {
      var uvconn = UVConnection.new()
      if (_uvserver.accept(uvconn)) {
        Connection.new(uvconn)
      } else {
        uvconn.close()
      }
    }
```

### TCPServer

```js
class TCPServer {
    construct new(ip, port) {}
    newIncomingConnection() {} // delegated
    onConnect=(fn) {}
    onConnect {} 
    serve() {}
    stop() {}
}
```

One simply creates a new instance, provides a `onConnect` handler, then calls `serve()`.  For example a small echo server:

```js
var server = TCPServer.new("127.0.0.1",7000)
server.onConnect = Fn.new() { |conn|
    var data 
    while (data = conn.readAll()) {
        conn.write(data)
    }
}
server.serve()
```


### Connection

```js
class Connection {
    static Open {}
    static Closed {}

    // creates a new connection associated with the low-level UVConnection
    construct new(uvconn) {}

    // establishes and returns a new connection
    static connect(ip, port) {}

    // status
    isClosed {}
    isOpen {}
    buffer_ {}

    // output
    print(data) {}
    write(data) {}
    writeBytes(strData) {}

    // instantly returns the read buffer or null if nothing to read
    readImmediate() {}

    // reads all data from the buffer (waiting for data if need be)
    readAll() {}

    // seek forward in the buffer by x bytes,
    // you can seek past the end, which will just leave the buffer empty
    // intended to be used in combination with `_buffer` to implement custom read functions in consumers
    seek(bytes) {}

    // read data from the buffer as bytes (into a string object)
    readBytes(bytes) {}

    // read a `\n` terminated line from the buffer
    readLine() {}

    // pauses the current Fiber until data is available,
    // it will wake back up when new data is received
    waitForData() {}

    // closes the connection
    close() {}

    // delegated
    // handles when new data is received on the connection
    // adds to buffer and signals if a fiber was waiting for new data
    dataReceived(data) 
}
```

All `read*` functions other than `readImmediate` will sleep the Fiber (via `waitForData`) and wait for data to be received if the buffer is empty or cannot fulfill the current read request (such as trying to read a line when a `\` has not yet been seen).

Exactly how to handle connections disconnecting in the middle of read requests is a question.  For example if we're waiting for a line of data with `readLine` and have a partial line in the buffer...

- should we return `null` (dropped the partial line)?
- should we return the portion of the line we have so far?
- should we `Fiber.abort`?

Currently this is signaled by `dataReceived` receiving a `null` value (EOF), at which point it marks the connection as closed.  I've tried to make sensible decisions based on how other frameworks handle this (see my comments in code).  For example `readLine` returns `null` and leaves an incomplete line in the buffer.  A program could detect the EOF easily enough and then call `readAll()` if that last bit of data was critical for operation.

This is generally the strategy I've used - control returns to the reader and `null` is used to signal to the reader the end has been reached.  This works because these functions by default pause and wait - there is no other circumstance where they would return `null`.


Example usage:

```js
var conn = Connection.connect("google.com", 80)
conn.write("GET / HTTP/1.1\r\nHost: www.google.com\r\nAccept: */*\r\n\r\n")
while (data=conn.readAll()) {
  System.print(data)
}
```


### DNS

- `lookup(hostname)` - returns the first matching IP address from DNS or aborts

Not a lot to see here.  Eventually this would need to be expanded to handle multiple results, etc.  Currently the entire stack only works with IP v4 stuff.


### NetworkError

A small wrapper around network errors because I don't think the Wren practice of aborting with strings scales well. When rescuing errors one should have an easy way to determine what type of error was thrown, hence a beginning to build a small class hierarchy.

I'm not necessarily proposing this for CLI - but it's there now, so I'm explaining it.  Eventually this code will land in my own projects where such things are a given (error classes).  If this was to be merged into CLI proper obviously errors could be simplified, if needed.

Or `raise()` could merely be patched to `abort` with `toString` rather than `this`. (say if the network library was say vendored from an outside source)

```js
class NetworkError {
  construct new(msg, errCode) {}
  static fromCode(err) {}
  error {}
  error=(e) 
  message {}
  message=(m) 
  toString {}
  raise() 
}
```

### AsyncHttpServer

Found in `play/asyncserver.wren`.  For details, see the source, but here is an example.  Currently `curl` can connect to it and fetch a basic page, but that's about it.  This is a very-early port of the [asynchttpserver](https://nim-lang.org/docs/asynchttpserver.html) from [Nim](https://nim-lang.org).

```js
var server = AsyncHttpServer.new()
var cb = Fn.new { |request, response |
  // System.print("%(request.requestMethod) %(request.url) %(request.headers)")
  var headers = {"Content-type": "text/plain; charset=utf-8"}
  response.status = 200
  response.body = "Hello World"
  response.headers = headers
  response.respond()
}

server.listen("127.0.0.1",8080)
while (true) {
  if (server.shouldAcceptRequest) {
    server.acceptRequest(cb)
  } else {
    Timer.sleep(500)
  }
}
```
