import "network" for Connection, UVConnection
import "timer" for Timer


var data 
var conn = Connection.connect("142.251.32.4", 80)
// var conn = Connection.new(uv)
conn.write("GET / HTTP/1.1\r\nHost: www.google.com\r\nAccept: */*\r\n\r\n")
// conn.write("HEAD / HTTP/1.1\r\nHost: www.google.com\r\nAccept: */*\r\n\r\n")
// System.print(conn)
while (data=conn.readAll()) {
  System.print(data)
  // conn.write("GET / HTTP/1.1\r\nHost: 142.250.191.142\r\n\r\n")
}
// conn.write("HEAD / HTTP/1.1\r\nHost: google.com\r\nAccept: */*\r\n\r\n")
// Timer.sleep(200)
// data=conn.read()
// System.print(data)

System.print("done")
// Timer.sleep(2000)