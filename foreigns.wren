import "process" for Process
import "io" for File

class Module {
    name { _name }
    classes { _classes }
    construct new(name) {
        _name = name
        _classes = []
    }
}

class Cls {
    name { _name }
    methods { _methods }
    widest { _widest }
    widest=(w) { _widest = w }
    construct new(name) {
        _widest = 0
        _name = name
        _methods = []
    }
}

class Method {
    name { _name }
    is_static { _is_static }
    signature { _signature }
    construct new(name, is_static, signature) {
        _name = name
        _is_static = is_static
        _signature = signature
    }
}

class Foreigns {

    construct new(file, outfile) {

        if(!File.exists(file)) {
            fail("given file not found: `%(file)`")
        }

        var string = File.read(file)
        if(string.count == 0) {
            fail("string had 0 length, doing nothing")
        }

        var modules = parse(string)
        
        dump(modules) //noise

        var generated = generate(modules)

        File.create(outfile) {|file| 
            file.writeBytes(generated)
        }

    } //new

    add(s, v) { add(s,v,1) }
    add(s, v, n) { s + v + "\n"*n }

    sanitize(string) {

        var out = string[0..-1]
            out = split(string, "/").join("_")
            out = split(out, "-").join("_")
            out = split(out, ".").join("_")

        return out

    } //sanitize

    tab(c) { " "*c }
    generate(modules) {

        var tabs = 3
        var nullptr = "nullptr"

        var mod = ""
        var fns = ""

        for(module in modules) {

            var module_name = sanitize(module.name)
            var bind_method = "bind_%(module_name)_method"

            mod=add(mod, "static WrenForeignMethodFn %(bind_method)(WrenVM* vm, bool is_static, const char* signature) {", 2)

            for(c in module.classes) {
                
                mod=add(mod, tab(tabs) + "// %(module.name) `%(c.name)`",2)
                fns=add(fns, tab(tabs) + "// %(module.name) `%(c.name)`",2)

                for(fn in c.methods) {
                    
                    var method_name = "%(module_name)_%(c.name)_%(fn.name)"
                    
                        //add the module returns
                    var space = tabs+(c.widest - fn.signature.count)
                    mod=add(mod, tab(tabs*2) + "if(strcmp(signature, \"%(fn.signature)\") == 0)%(" "*space)return %(method_name);")
                    
                        //generate the method handler
                    fns=add(fns, tab(tabs*2) + "static void %(method_name)(WrenVM *vm) {")
                    fns=add(fns, tab(tabs*2) + "} //%(method_name)",2)

                }

                mod=add(mod, "")

            } //each class

            mod=add(mod, tab(tabs) + "return %(nullptr);",2)
            mod=add(mod, "} //%(bind_method)",2)

        } //each module

        var body = ""
        body=add(body, tab(tabs)+"//This code is for inside of the bindForeignMethodFn function you give wren")
        body=add(body, tab(tabs)+"//you only need the body, but it includes the rest for example")

        body=add(body, "static WrenForeignMethodFn bind_method(WrenVM* vm, const char* module, const char* class_name, bool is_static, const char* signature) {",2)
        
        for(module in modules) {
            var module_name = sanitize(module.name)
            var bind_method = "bind_%(module_name)_method"
            body=add(body, tab(tabs) + "if(strcmp(module, \"%(module_name)\") == 0) return %(bind_method)(vm, is_static, signature);")

        }

        body=add(body, "")
        body=add(body, tab(tabs) + "return %(nullptr);",2)
        body=add(body, "} //bind_method",2)

        var result = "\n\n"
        result=add(result, fns, 2)
        result=add(result, mod, 2)
        result=add(result, body, 2)

        return result

    } //generate

    fail(reason) { 
        Fiber.abort(reason) 
    }
    
    parse(string) {

        var result = []
        var lines = split(string,"\n")
        var current_module = null
        var current_class = null
        var module_bit = "module: "
        var class_bit = "class: "

        lines.each{|line|

            line = trim(line)

            if(line.count < 1 || line.startsWith("//")) {

                //skip blank and comments

            } else if(line.startsWith(module_bit)) {

                var name = line[module_bit.count..-1]
                
                if(current_module==null || current_module.name != name) {
                    current_module = Module.new(name)
                    result.add(current_module)
                }
                
            } else if(line.startsWith(class_bit)) {

                if(current_module == null) fail("`%(class_bit)` requires a parent `%(module_bit)`")

                current_class = Cls.new(line[class_bit.count..-1])
                current_module.classes.add(current_class)

            } else {

                var parts = split(line, " ")

                if(current_class == null) fail("methods require a `%(class_bit)` above them")
                if(parts.count != 2) fail("method should be `is_static_bool signature_string` separated by a space!")

                var signature = parts[1] //:todo:validation
                var name = signature[0..signature.indexOf("(")-1]
                var is_static = parts[0] != "false"

                current_class.methods.add(Method.new(name, is_static, signature))

            } //

        } //each line

        for(m in result) {
            for(c in m.classes) {
                var max = 0
                for(f in c.methods) {
                    if(f.signature.count > max) max = f.signature.count
                }
                c.widest = max
            }
        }

        return result

    } //parse

    dump(modules) {
        for(m in modules) {
            System.print("module: %(m.name)")
            for(c in m.classes) {
                System.print("  class: %(c.name)")
                for(fn in c.methods) {
                    System.print("    %(fn.is_static) %(fn.signature)")
                }
            }
        }
    }

    split(string, delim) {

        var pos = string.indexOf(delim)
        if(pos == -1) return [string]

        var result = []
        var tmp = string[0..-1]

        while(pos != -1) {

            var cut = ""
            if(pos != 0) {
                cut = tmp[0..pos-1]
            }

            result.add(cut)
            tmp = tmp[pos+1..-1]
            pos = tmp.indexOf(delim)

        }

        result.add(tmp)
        return result

    } //split

    trim(string) {

        if(string == null) return string
        if(string.count == 0) return string

        var tab = "\t"
        var space = " "

        while (string.count > 0 && (string[0] == space || string[0] == tab)) {
            string = string[1..-1]
        }

        while (string.count > 0 && (string[-1] == space || string[-1] == tab)) {
            string = string[0...-1]
        }

        return string

    } //trim

} //Foreigns


var args = Process.arguments
if(args.count == 2) {
    Foreigns.new(args[0], args[1])
} else {
    System.print("usage: [input_file] [output_file.c]")
}
