import "io" for File
import "os" for Platform

if (Platform.isWindows) {
  System.print(File.basename("") == "")                     // expect: true
  System.print(File.basename(".") == ".")                   // expect: true
  System.print(File.basename("..") == "..")                 // expect: true
  System.print(File.basename("file.txt") == "file.txt")     // expect: true

  System.print(File.basename("\\") == "\\")                 // expect: true
  System.print(File.basename("\\foo") == "foo")             // expect: true
  System.print(File.basename("\\foo\\") == "foo")           // expect: true
  System.print(File.basename("\\foo\\bar") == "bar")        // expect: true
  System.print(File.basename("\\foo\\bar\\") == "bar")      // expect: true
  System.print(File.basename("\\foo\\bar\\baz") == "baz")   // expect: true

  System.print(File.basename("dir1\\dir2\\file") == "file") // expect: true
  System.print(File.basename("dir1\\file")       == "file") // expect: true

  System.print(File.basename("dir1\\")     == "dir1")       // expect: true
  System.print(File.basename("dir1\\\\\\") == "dir1")       // expect: true

  System.print(File.basename("\\\\\\\\\\\\\\\\\\") == "\\") // expect: true
  System.print(File.basename("\\\\\\foo")         == "foo") // expect: true
  System.print(File.basename("\\\\\\foo\\\\")     == "foo") // expect: true
  System.print(File.basename("\\\\\\foo\\\\bar")  == "bar") // expect: true
   
  // 2 argument signature
  System.print(File.basename("dir1\\file.txt", [".txt"])        == "file")     // expect: true
  System.print(File.basename("dir1\\file.txt", [".c", ".txt"])  == "file")     // expect: true
  System.print(File.basename("dir1\\file.txt", [".c", ".wren"]) == "file.txt") // expect: true


} else {
  System.print(File.basename("") == "")                   // expect: true
  System.print(File.basename(".") == ".")                 // expect: true
  System.print(File.basename("..") == "..")               // expect: true
  System.print(File.basename("file.txt") == "file.txt")   // expect: true

  System.print(File.basename("/") == "/")                 // expect: true
  System.print(File.basename("/foo") == "foo")            // expect: true
  System.print(File.basename("/foo/") == "foo")           // expect: true
  System.print(File.basename("/foo/bar") == "bar")        // expect: true
  System.print(File.basename("/foo/bar/") == "bar")       // expect: true
  System.print(File.basename("/foo/bar/baz") == "baz")    // expect: true

  System.print(File.basename("dir1/dir2/file") == "file") // expect: true
  System.print(File.basename("dir1/file")      == "file") // expect: true

  System.print(File.basename("dir1/")   == "dir1")        // expect: true
  System.print(File.basename("dir1///") == "dir1")        // expect: true

  System.print(File.basename("/////////")   == "/")       // expect: true
  System.print(File.basename("///foo")      == "foo")     // expect: true
  System.print(File.basename("///foo//")    == "foo")     // expect: true
  System.print(File.basename("///foo//bar") == "bar")     // expect: true

  // 2 argument signature
  System.print(File.basename("dir1/file.txt", [".txt"])        == "file")     // expect: true
  System.print(File.basename("dir1/file.txt", [".c", ".txt"])  == "file")     // expect: true
  System.print(File.basename("dir1/file.txt", [".c", ".wren"]) == "file.txt") // expect: true
}
