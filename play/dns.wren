import "network" for DNS
import "timer" for Timer


// System.print("it is %(DNS.address("snoppy"))")

var addy = DNS.address("twitter.com")
System.print("it is %(addy)")
// System.print(DNS.address("www.google.com"))

// Timer.sleep(500)
