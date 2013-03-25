injector = 
    
    #
    # **function** `injector.inject (module [,module2, ...]) ->` 
    # **function** `injector.inject [list,of,objects], (list, of, objects, module [,module2, ...]) ->`
    # 
    # Injects modules by name into the function at lastarg.
    # 
    # 
    # *Usage*
    # 
    # <pre>
    #
    #    inject [1,2,3], (one, two, three, should) -> 
    #
    #        should.should.equal require 'should'
    #        one.should.equal   1
    #        two.should.equal   2
    #        three.should.equal 3
    #
    # </pre>
    # 

    inject: ->

        if typeof arguments[0] == 'function' 

            fn = arguments[0]
            fn.apply null, injector.support.loadServices injector.support.fn2modules fn

        else

            list = arguments[0]

            for key of arguments

                #
                # fn is the last argument
                #

                fn = arguments[key]

            fn.apply null, injector.support.loadServices injector.support.fn2modules( fn ) , list

    #
    # also export injector_support (potentially usefull functionality)
    #

    support: require './injector_support'

module.exports = injector
