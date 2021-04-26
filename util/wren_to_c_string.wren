#!./bin/wren_cli

import "os" for Process
import "io" for File

// The source for the Wren modules that are built into the VM or CLI are turned
// include C string literals. This way they can be compiled directly into the
// code so that file IO is not needed to find and read them.
// 
// These string literals are stored in files with a ".wren.inc" extension and
// #included directly by other source files. This generates a ".wren.inc" file
// given a ".wren" module.

var PREAMBLE = "// Generated automatically from {0}. Do not edit.
static const char* {1}ModuleSource =
{2};
"

class WrenToCInclude {
    construct new(path) {
        _source = File.read(path).trim()
        _path = path
    }
    compile() {
        var source = _source.split("\n").map { |line|
            line = line.replace("\"", "\\\"")
            return "\""  + line + "\\n\""
        }.join("\n")
        
        return PREAMBLE.
            replace("{0}", _path).
            replace("{1}", File.splitext(File.basename(_path))[0]).
            replace("{2}", source)
    }
}

var HELP = "usage: wren_to_c_string.wren output input
error: too few arguments"

var main = Fn.new {
    if (Process.arguments.count < 2) {
        System.print(HELP)
        return
    }

    var output = Process.arguments[0]
    var input_path = Process.arguments[1]

    var header = WrenToCInclude.new(input_path)

    var f = File.create(output)
    f.writeBytes(header.compile())
}

// def main():
//   parser = argparse.ArgumentParser(
//       description="Convert a Wren library to a C string literal.")
//   parser.add_argument("output", help="The output file to write")
//   parser.add_argument("input", help="The source .wren file")

//   args = parser.parse_args()

//   with open(args.input, "r") as f:
//     wren_source_lines = f.readlines()

//   module = os.path.splitext(os.path.basename(args.input))[0]
//   module = module.replace("opt_", "")
//   module = module.replace("wren_", "")

//   c_source = wren_to_c_string(args.input, wren_source_lines, module)

//   with open(args.output, "w") as f:
//     f.write(c_source)


main.call()
