class Module {
    construct new(importer, module, home) {
        _importer = importer
        _module = module
        _home = home
    }
    static resolve(importer, module, home) {
        var res = Module.new(importer, module, home)
        return res.relativeResolver || 
            res.wrenModulesResolver ||
            res.wrenHomeResolver 
    }
    relativeResolver {
        if (!_module.startsWith("./")) return _module

        var locations = [
            Path.join(["%(_module).wren"]),
            Path.join(["%(_module)/%(_module).wren"])
        ]
        for (x in locations) {
            System.print(x)
            if (File.existsSync(x)) return x
        }        
    }
    wrenHomeResolver {
        var locations = [
            Path.join([_home,".wren/lib",_module + ".wren"]),
            Path.join([_home,".wren",_module + ".wren"])
        ]
        for (x in locations) {
            System.print(x)
            if (File.existsSync(x)) return x
        }        
    }
}

class Path {
    static join(list) { list.join("/").replace("//","/") }
}

class File {
    foreign static existsSync(s)
}



