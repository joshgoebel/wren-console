import "io" for File

System.print(Fiber.new {
  File.create("file.temp") {|file|
    file.writeBytes("", "string")
  }
}.try()) // expect: Expected positive integer for 'offset'

File.delete("file.temp")
