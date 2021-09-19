import "io" for File
import "os" for Platform

var tests = []

tests.add({"input": "", "expected": ""})  // 0
tests.add({"input": ".", "expected": "."})  // 1
tests.add({"input": "..", "expected": ".."})  // 2
tests.add({"input": "file.txt", "expected": "file.txt"})  // 3
tests.add({"input": "/", "expected": "/"})  // 4
tests.add({"input": "/foo", "expected": "foo"}) // 5
tests.add({"input": "/foo/", "expected": "foo"})  // 6
tests.add({"input": "/foo/bar", "expected": "bar"}) // 7
tests.add({"input": "/foo/bar/", "expected": "bar"})  // 8
tests.add({"input": "/foo/bar/baz", "expected": "baz"}) // 9
tests.add({"input": "dir1/dir2/file", "expected": "file"})  // 10
tests.add({"input": "dir1/file"     , "expected": "file"})  // 11
tests.add({"input": "dir1/"  , "expected": "dir1"}) // 12
tests.add({"input": "dir1///", "expected": "dir1"}) // 13
tests.add({"input": "/////////"  , "expected": "/"})  // 14
tests.add({"input": "///foo"     , "expected": "foo"})  // 15
tests.add({"input": "///foo//"   , "expected": "foo"})  // 16
tests.add({"input": "///foo//bar", "expected": "bar"})  // 17

// 2 argument signature
tests.add({"input": "dir1/file.txt", "suffixes": [".txt"]       , "expected": "file"})  // 18
tests.add({"input": "dir1/file.txt", "suffixes": [".c", ".txt"] , "expected": "file"})  // 19
tests.add({"input": "dir1/file.txt", "suffixes": [".c", ".wren"], "expected": "file.txt"})  // 20


if (Platform.isWindows) {
  tests = tests.map {|t|
    return {
      "input": t["input"].replace("/", """\\"""),       // ugh
      "expected": t["expected"].replace("/", """\\"""),
    }
  }.toList
}

// tediously, we need to spell out the tests one-by-one
System.print(File.basename(tests[0]["input"]) == tests[0]["expected"]) // expect: true
System.print(File.basename(tests[1]["input"]) == tests[1]["expected"]) // expect: true
System.print(File.basename(tests[2]["input"]) == tests[2]["expected"]) // expect: true
System.print(File.basename(tests[3]["input"]) == tests[3]["expected"]) // expect: true
System.print(File.basename(tests[4]["input"]) == tests[4]["expected"]) // expect: true
System.print(File.basename(tests[5]["input"]) == tests[5]["expected"]) // expect: true
System.print(File.basename(tests[6]["input"]) == tests[6]["expected"]) // expect: true
System.print(File.basename(tests[7]["input"]) == tests[7]["expected"]) // expect: true
System.print(File.basename(tests[8]["input"]) == tests[8]["expected"]) // expect: true
System.print(File.basename(tests[9]["input"]) == tests[9]["expected"]) // expect: true
System.print(File.basename(tests[10]["input"]) == tests[10]["expected"]) // expect: true
System.print(File.basename(tests[11]["input"]) == tests[11]["expected"]) // expect: true
System.print(File.basename(tests[12]["input"]) == tests[12]["expected"]) // expect: true
System.print(File.basename(tests[13]["input"]) == tests[13]["expected"]) // expect: true
System.print(File.basename(tests[14]["input"]) == tests[14]["expected"]) // expect: true
System.print(File.basename(tests[15]["input"]) == tests[15]["expected"]) // expect: true
System.print(File.basename(tests[16]["input"]) == tests[16]["expected"]) // expect: true
System.print(File.basename(tests[17]["input"]) == tests[17]["expected"]) // expect: true

System.print(File.basename(tests[18]["input"], tests[18]["suffixes"]) == tests[18]["expected"]) // expect: true
System.print(File.basename(tests[19]["input"], tests[19]["suffixes"]) == tests[19]["expected"]) // expect: true
System.print(File.basename(tests[20]["input"], tests[20]["suffixes"]) == tests[20]["expected"]) // expect: true
