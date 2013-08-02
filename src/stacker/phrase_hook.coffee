#
# create before() and after() for hook registration
#

beforeHooks = each: [], all: []
afterHooks  = each: [], all: []

Object.defineProperty global, 'before',
    enumerable: false
    get: -> (opts = {}) -> 
        beforeHooks.each.push opts.each if typeof opts.each == 'function'
        beforeHooks.all.push  opts.all  if typeof opts.all  == 'function'


Object.defineProperty global, 'after',
    enumerable: false
    get: -> (opts = {}) -> 
        afterHooks.each.push opts.each if typeof opts.each == 'function'
        afterHooks.all.push  opts.all  if typeof opts.all  == 'function'


module.exports = hook = 

    runHooks: (hookType, stack, done) -> 

        #
        # run all beforeEach and afterEach hooks in the stack
        # (for leafOnly mode)
        # 

        done()



    beforeAll: (opts, control) -> 

        #
        # return a function to handle calls to beforeAll
        # on the phrase stack's async injector loop
        #

        return (done, inject) -> 

            #
            # assign registered hooks
            #

            beforeEach = beforeHooks.each.pop()
            beforeAll  = beforeHooks.all.pop()
            afterEach  = afterHooks.each.pop()
            afterAll   = afterHooks.all.pop()

            control.beforeEach ||= beforeEach
            control.beforeAll  ||= beforeAll
            control.afterEach  ||= afterEach
            control.afterAll   ||= afterAll

            if typeof control.beforeAll == 'function'

                return control.beforeAll.call this, done unless opts.global
                return control.beforeAll.call null, done

            done()


    beforeEach: (opts, control) -> 

        return (done, inject) -> 

            #
            # ensure injection of (phrase, control, fn)
            #

            unless typeof inject.args[2] == 'function'

                argCount = inject.args.length

                inject.args[2] = inject.args[1] || -> 

                    if argCount == 0

                        #
                        # call to stacker with no args
                        # ----------------------------
                        # 
                        # * pop stack and resolve parent's injection promise
                        # 

                        opts.stack.pop()
                        control.defer.resolve()

                if argCount == 1

                    # 
                    # console.log "TODO: something useful at phrase: '#{inject.args[0]}'"
                    # 
                    # eg. pending specs
                    # 

                    'noop'
                
                #
                # default arg2 as empty control hash
                #

                inject.args[1] = {}

            #
            # attach this injection promise to control hash
            #

            inject.args[1].defer = inject.defer

            opts.stack.push element = 

                element:    opts.elementName
                phrase:     inject.args[0]
                defer:      inject.defer
                queue:      inject.queue
                current:    inject.current
                beforeEach: control.beforeEach || (done) -> done()
                afterEach:  control.afterEach  || (done) -> done()


            if opts.context.leafOnly

                opts.context.isLeaf 

                    element: opts.elementName
                    phrase: inject.args[0]
                    fn: inject.args[2]

                    (leaf) ->

                        if leaf

                            #
                            # flag element as leaf so that afterEach does not need
                            # to perform the same investigation
                            #

                            element.leaf = true
                            hook.runHooks 'beforeEach', opts.stack, done


            done()




    afterAll: (opts, control) -> 

        return (done, inject) -> 

            if typeof control.afterAll == 'function'

                return control.afterAll.call this, done unless control.global
                return control.afterAll.call null, done

            done()


