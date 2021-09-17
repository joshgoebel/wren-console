import "io" for File

System.print(Fiber.new {
  File.create("file.temp") {|file|
    file.writeBytes(123)
  }
}.try()) // expect: Expected 'String' for 'bytes'

File.delete("file.temp")
