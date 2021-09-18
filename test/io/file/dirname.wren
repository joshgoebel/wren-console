import "io" for File
import "os" for Platform

if (Platform.isWindows) {
  System.print(File.dirname("") == ".")           // expect: true
  System.print(File.dirname(".") == ".")          // expect: true
  System.print(File.dirname("..") == ".")         // expect: true
  System.print(File.dirname("file.txt") == ".")   // expect: true

  System.print(File.dirname("\\") == "\\")                      // expect: true
  System.print(File.dirname("\\foo") == "\\")                   // expect: true
  System.print(File.dirname("\\foo\\") == "\\")                 // expect: true
  System.print(File.dirname("\\foo\\bar") == "\\foo")           // expect: true
  System.print(File.dirname("\\foo\\bar\\") == "\\foo")         // expect: true
  System.print(File.dirname("\\foo\\bar\\baz") == "\\foo\\bar") // expect: true

  System.print(File.dirname("dir1\\dir2\\file") == "dir1\\dir2") // expect: true
  System.print(File.dirname("dir1\\file") == "dir1")             // expect: true

  System.print(File.dirname("dir1\\") == ".")      // expect: true
  System.print(File.dirname("dir1\\\\\\") == ".")  // expect: true

  System.print(File.dirname("\\\\\\\\\\\\\\\\\\") == "\\")      // expect: true
  System.print(File.dirname("\\\\\\foo") == "\\")               // expect: true
  System.print(File.dirname("\\\\\\foo\\\\") == "\\")           // expect: true
  System.print(File.dirname("\\\\\\foo\\\\bar") == "\\\\\\foo") // expect: true

} else {
  System.print(File.dirname("") == ".")            // expect: true
  System.print(File.dirname(".") == ".")           // expect: true
  System.print(File.dirname("..") == ".")          // expect: true
  System.print(File.dirname("file.txt") == ".")    // expect: true

  System.print(File.dirname("/") == "/")           // expect: true
  System.print(File.dirname("/foo") == "/")        // expect: true
  System.print(File.dirname("/foo/") == "/")       // expect: true
  System.print(File.dirname("/foo/bar") == "/foo") // expect: true
  System.print(File.dirname("/foo/bar/") == "/foo")           // expect: true
  System.print(File.dirname("/foo/bar/baz") == "/foo/bar")    // expect: true

  System.print(File.dirname("dir1/dir2/file") == "dir1/dir2") // expect: true
  System.print(File.dirname("dir1/file") == "dir1")           // expect: true

  System.print(File.dirname("dir1/") == ".")       // expect: true
  System.print(File.dirname("dir1///") == ".")     // expect: true

  System.print(File.dirname("/////////") == "/")              // expect: true
  System.print(File.dirname("///foo") == "/")                 // expect: true
  System.print(File.dirname("///foo//") == "/")               // expect: true
  System.print(File.dirname("///foo//bar") == "///foo")       // expect: true
}
