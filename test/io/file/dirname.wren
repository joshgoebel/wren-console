import "io" for File
import "os" for Platform

var tests = []
tests.add({"input": "", "expected": "."})  // 0
tests.add({"input": ".", "expected": "."}) // 1
tests.add({"input": "..", "expected": "."})  // 2
tests.add({"input": "file.txt", "expected": "."})  // 3
tests.add({"input": "/", "expected": "/"}) // 4
tests.add({"input": "/foo", "expected": "/"})  // 5
tests.add({"input": "/foo/", "expected": "/"}) // 6
tests.add({"input": "/foo/bar", "expected": "/foo"}) // 7
tests.add({"input": "/foo/bar/", "expected": "/foo"})  // 8
tests.add({"input": "/foo/bar/baz", "expected": "/foo/bar"}) // 9
tests.add({"input": "dir1/dir2/file", "expected": "dir1/dir2"})  // 10
tests.add({"input": "dir1/file", "expected": "dir1"})  // 11
tests.add({"input": "dir1/", "expected": "."}) // 12
tests.add({"input": "dir1///", "expected": "."}) // 13
tests.add({"input": "/////////", "expected": "/"}) // 14
tests.add({"input": "///foo", "expected": "/"})  // 15
tests.add({"input": "///foo//", "expected": "/"})  // 16
tests.add({"input": "///foo//bar", "expected": "///foo"})  // 17

if (Platform.isWindows) {
  tests = tests.map {|t|
    return {
      "input": t["input"].replace("/", """\\"""),
      "expected": t["expected"].replace("/", """\\"""),
    }
  }.toList
}

System.print(File.dirname(tests[0]["input"]) == tests[0]["expected"]) // expect: true
System.print(File.dirname(tests[1]["input"]) == tests[1]["expected"]) // expect: true
System.print(File.dirname(tests[2]["input"]) == tests[2]["expected"]) // expect: true
System.print(File.dirname(tests[3]["input"]) == tests[3]["expected"]) // expect: true
System.print(File.dirname(tests[4]["input"]) == tests[4]["expected"]) // expect: true
System.print(File.dirname(tests[5]["input"]) == tests[5]["expected"]) // expect: true
System.print(File.dirname(tests[6]["input"]) == tests[6]["expected"]) // expect: true
System.print(File.dirname(tests[7]["input"]) == tests[7]["expected"]) // expect: true
System.print(File.dirname(tests[8]["input"]) == tests[8]["expected"]) // expect: true
System.print(File.dirname(tests[9]["input"]) == tests[9]["expected"]) // expect: true
System.print(File.dirname(tests[10]["input"]) == tests[10]["expected"]) // expect: true
System.print(File.dirname(tests[11]["input"]) == tests[11]["expected"]) // expect: true
System.print(File.dirname(tests[12]["input"]) == tests[12]["expected"]) // expect: true
System.print(File.dirname(tests[13]["input"]) == tests[13]["expected"]) // expect: true
System.print(File.dirname(tests[14]["input"]) == tests[14]["expected"]) // expect: true
System.print(File.dirname(tests[15]["input"]) == tests[15]["expected"]) // expect: true
System.print(File.dirname(tests[16]["input"]) == tests[16]["expected"]) // expect: true
System.print(File.dirname(tests[17]["input"]) == tests[17]["expected"]) // expect: true
