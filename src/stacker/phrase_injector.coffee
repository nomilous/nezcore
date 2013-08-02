sequence         = require 'when/sequence'
{defer}          = require 'when'

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


module.exports = injector = 

    runHooks: (hookType, stack, done) -> 

        #
        # run all beforeEach and afterEach hooks in the stack
        # (for leafOnly mode)
        # 

        # 
        # for loop returns array of functions
        # each deferring a call to the hook
        # at that phrase
        # 

        sequence( for phrase in stack

            do (phrase) -> -> 

                #
                # do() locks each phrase into a closure
                # to prevent the for loop having nexted
                # all deferrals to refer onto the last 
                # phrase in the stack by the time the 
                # sequence traversal begins, 
                # 
                # but still returns the deferred function 
                # for the sequence bound function array
                #

                deferral = defer()

                         # 
                         # each deferral resolver is passed 
                         # in on the call to the hook,
                         # as the done function
                         # 
                         # beforeEach:  (done) -> 
                         # afterEach:   (done) -> 
                         # 

                phrase[hookType]( deferral.resolve )
                deferral.promise

        ).then done, done

                #
                # done is promise resolve and reject handler
                #




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
                            return injector.runHooks 'beforeEach', opts.stack, done

                        done()

            else if typeof control.beforeEach == 'function'

                return control.beforeEach done unless control.global
                return control.beforeEach.call null, done

            else done()


    afterEach: (opts, control) -> 

        return (done, inject) -> 

            element = opts.stack[ opts.stack.length - 1 ]

            sequence([

                    #
                ->  # when leafOnly mode, run hook stack if element is leaf
                    #
                    
                    return unless element.leaf
                    step = defer()

                    #
                    # afterEach hooks need to be run in reverse stack order
                    # 

                    reversed = []
                    reversed.unshift phrase for phrase in opts.stack
                    injector.runHooks 'afterEach', reversed, (result) ->

                        # 
                        # TODO: handle errors in hooks
                        # 
                        # return action.reject result if result instanceof Error
                        # cannot reject because entire sequence must run...
                        # 

                        step.resolve result

                    step.promise

                    #
                ->  # pop the stack
                    #

                    opts.stack.pop()

                    


            ]).then done, done


    afterAll: (opts, control) -> 

        return (done, inject) -> 

            if typeof control.afterAll == 'function'

                return control.afterAll.call this, done unless control.global
                return control.afterAll.call null, done

            done()


