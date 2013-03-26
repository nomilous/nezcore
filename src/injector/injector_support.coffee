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
            regexp    = new RegExp "(\\w*) = _arg.#{chain[0]}"
            targetArg = funcStr.match( regexp )[1]


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

            services.push support.findModule config

        #console.log "services:", services

        return services


    loadNested: (services, config) -> 

        #
        # multiple modules to be injected through _arg
        #

        modules  = {}
        sequence = []
        _arg     = {}

        for target of config

            chain      = config[target]
            moduleName = chain[0]       # could be a class
            className  = chain[1]       # could be a function

            #
            # keep ref to the sequence of the modules being injected
            #
            sequence.push moduleName

            if typeof modules[moduleName] == 'undefined'

                #
                # load the module and define the getter (_arg.moduleName)
                #

                modules[moduleName] = 

                    module: support.findModule( module: moduleName )

                    #
                    # the same module could be injected multiple times
                    # as (module:class1, module:class2)
                    #
                    # each requires reference to control what is returned
                    # from _arg.moduleName 
                    # 

                    stack: []

                # console.log 'creating _arg.%s for target:', moduleName, config[target]

                Object.defineProperty _arg, moduleName, 

                    get: -> 

                        # 
                        # modules[moduleName].stack.pop() only ever pops 
                        # from modules.['the last moduleName injected']
                        # 
                        # so this uses the sequence as assembled
                        # 

                        modules[sequence.shift()].stack.pop()

                    enumerable: true


            #
            # populate the stack for the getter to pop from 
            # for the given _arg.moduleName
            #

            if typeof className == 'undefined'

                #
                # entire module is being injected
                # 

                modules[moduleName].stack.unshift modules[moduleName].module

            else

                #
                # focussed module:classname is being injected
                # 

                modules[moduleName].stack.unshift modules[moduleName].module[className]



        #
        # append _arg to the injectables
        #

        services.push _arg
        return services


    findModule: (config) ->

        unless config.module.match /^[A-Z]/

            #
            # not CamelCase, getting node_module 
            #            

            return require config.module


        #
        # load a locally defined in (lib|app|bin)
        #

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


