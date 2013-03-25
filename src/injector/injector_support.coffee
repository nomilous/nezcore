Inflection = require 'inflection'
wrench     = require 'wrench'
fs         = require 'fs'

#
# TODO: fix 'Cannot redefine property: fing'
#       very strange...
#

require 'fing' if typeof fing == 'undefined'

module.exports = support = 

    fn2modules: (fn) ->

        modules = []
        funcStr = fn.toString()

        for arg in fn.fing.args

            module = arg.name

            if module.match /^_arg/

                if funcStr.match /_ref = _arg/

                    support.mixedDepth modules, funcStr
                    
                else

                    support.uniformDepth modules, funcStr

            else 

                modules.push module: arg.name

        return modules


    mixedDepth: (modules, funcStr) -> 

        # console.log '\n\n%s\n\n', funcStr
        # console.log JSON.stringify modules, null, 2


        #
        # (mod0, mod2:class2, mod1:class1:function1, mod3:class3, mod4) -> 
        # 
        # as: 
        # 
        #   'class2 = _arg.mod2, (_ref = _arg.mod1, function1 = _ref.class1, class3 = _ref.mod3, mod4 = _ref.mod4);'
        # 
        # is not possible to use without somehow jumping over the fact that:
        # 
        #   '_ref = _arg.mod1' and then 'class3 = _ref.mod3 // when _ref is still _arg.mod1'
        # 

        throw new Error 'Mixed depth focussed injection not yet supported'


    uniformDepth: (modules, funcStr) -> 

        nestings = {}

        for narg in funcStr.match /_(arg|ref)\.(\w*)/g

            chain     = narg.split('.')
            ref       = chain.shift()
            targetArg = funcStr.match( new RegExp "(\\w*) = _arg.#{chain[0]}" )[1]

            #
            # "and final as flat"
            #
            chain.push targetArg unless chain[ chain.length - 1 ] == targetArg

            nestings[targetArg] = chain

        modules.push _nested: nestings


    loadServices: (dynamic, preDefined = []) -> 


        skip = preDefined.length

        services = preDefined

        for config in dynamic

            continue if skip-- > 0


            if config._nested

                support.loadNested services, config._nested
                continue

            if config.module.match /^[A-Z]/

                #
                # Inject local module (from ./lib or ./app)
                #

                services.push support.findModule config

            else

                #
                # Inject installed npm module
                #

                module = require config.module
                services.push module


        #console.log "services:", services

        return services


    loadNested: (services, config) -> 

        #
        # This function ''slide''s the hierarchy
        # so that the coffee script...
        # 
        #   (module1:class1) -> 
        #      class1.method 'arg'
        # 
        # ...as compiled to javascript... 
        # 
        #   function( _arg ) {
        #       var class1 = _arg.module1;
        #       class1.method('arg');
        #   }
        # 
        # ...actually has module1.class1 loaded 
        #    into var class1
        # 
        #

        services.push {}
        _arg = services[services.length - 1]

        for name of config

            #
            # re-arrange so that sending back through
            # loadServices has the necessary args
            # to append the specified service.
            #

            defn = config[name]
            rebuild = []

            for existing in services
                rebuild.push existing

            rebuild.push module: defn[0]

            #
            # send back through loadServices and then
            # pop off the new last service and insert
            # it into the 
            #

            support.loadServices rebuild, services
            nextService = services.pop()

            if defn.length > 1

                #
                # ''slide''
                #

                _arg[defn[0]] = nextService[name]

            else

                #
                # flat (no nesting)
                # 
                # necessary here because flat args that follow nested ones
                # also need to be appended into _arg, because...
                # 
                #    (flat1, module1:class1, flat2) -> 
                #      
                # ...becomes...
                # 
                #    function(flat1, _arg) {
                #        var class1, flat2;
                #        class1 = _arg.module1, flat2 = _arg.flat2;
                #    }
                #

                _arg[name] = nextService

    findModule: (config) ->

        name     = Inflection.underscore config.module
        stack    = fing.trace()
        previous = null

        for call in stack

            #
            # is the call coming from a spec run?
            #
            # ASSUMPTION1 
            # ===========
            # 
            # If the call is coming from a spec run then there
            # will be one instance of /spec/ in the callers 
            # path and it will be a subdirectory of the repo root.
            # 

            if call.file.match /injector_support.js$/

                #
                # ignore self in stack
                #

                continue

            if match = call.file.match /(.*)\/spec\/.*/

                path = match[1]
                modulePath = support.getModulePath name, path, ['lib','app','bin']
                return require modulePath if modulePath
                throw new Error "Injector failed to locate #{name}.js in #{path}"


            #
            # if not from a spec run then
            # 
            # ASSUMPTION2
            # ===========
            # 
            # The module to be injected will be located in 
            # either of the directory trees rooted at the
            # first matched instance of either /lib/, /app/
            # or /bin/ that immediately preceeds the first
            # stack call being made from the node_module 
            # loader itself 'module.js'
            # 
            #

            else if call.file == 'module.js'

                if match = previous.match /(.*)\/(lib|app|bin)\//

                    path = match[1]
                    modulePath = support.getModulePath name, match[1], [match[2]]
                    return require modulePath if modulePath
                    throw new Error "Injector failed to locate #{name}.js in #{path}"

                continue

            previous = call.file

        throw new Error "Injector failed to locate #{name}.js"

    getModulePath: (name, root, search) -> 

        #expression = "(.*\\/#{name})\\.(coffee|js)$" # darn...
        expression = "(.*#{name})\\.(coffee|js)$"

        for dir in search

            source = null

            searchPath = root + "/#{dir}"

            if fs.existsSync searchPath

                for file in wrench.readdirSyncRecursive(searchPath)

                    if match = file.match new RegExp expression

                        continue unless match[1].split('/').pop() == name # ...it

                        if source 

                            throw new Error "Found more than 1 source for module '#{name}'"

                        else

                            source = "#{searchPath}/#{match[1]}"

            return source


