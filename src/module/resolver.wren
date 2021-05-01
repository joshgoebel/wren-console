var WREN_MODULES = null

class Module {
    construct new(cwd, module, home) {
        _cwd = cwd
        // var pieces = module.split("~~")
        // _importer = pieces[0]
        // _module = pieces[1]
        _module = module
        _home = home
    }
    // static log(x) { System.print(x) }
    // log(x) { System.print(x) }
    log(x) {}
    static log(x) {}
    static resolve(cwd, module, home) {
        log("WREN Resolve: %(module) in %(cwd)")

        var res = Module.new(cwd, module, home)
        return res.relativeResolver || 
            res.wrenModulesResolver ||
            res.wrenHomeResolver 
    }
    findWrenModules() {
        if (WREN_MODULES != null) return WREN_MODULES

        log("SEARCHING for wren_modules")
        var pieces = _cwd.split("/")
        for (i in (pieces.count-1)..1) {
            var path = pieces[0..i].join("/") + "/wren_module"
            log(path)
            if (File.existsSync(path)) {
                WREN_MODULES = path
                return path
            }
        }
    }
    wrenModulesResolver {
        log("wren_modules resolver")
        var modules = findWrenModules()
        if (modules == null) return null 

        var locations = [
            Path.join([modules,_module + ".wren"]),
            Path.join([modules,_module,_module + ".wren"])
        ]
        for (x in locations) {
            log(x)
            if (File.existsSync(x)) return x
        }     

    }
    relativeResolver {
        if (!_module.startsWith("./")) return null

        var locations = [
            Path.join(["%(_module).wren"]),
            Path.join(["%(_module)/%(_module).wren"])
        ]
        for (x in locations) {
            log(x)
            if (File.existsSync(x)) return x
        }        
    }
    wrenHomeResolver {
        var locations = [
            Path.join([_home,".wren/lib",_module + ".wren"]),
            Path.join([_home,".wren",_module + ".wren"])
        ]
        for (x in locations) {
            log(x)
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



