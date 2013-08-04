sequence         = require 'when/sequence'
{defer}          = require 'when'
{deferral, util} = require 'also'


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

            do (phrase) -> 

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

                deferral.optional

                    #
                    # deferral.optional creates a deferral and
                    # passes the resolver as done to each hook...
                    # 

                    resolver: 'done'

                    #
                    # ...but only if hook's arg signature 
                    # contains `done`, otherwise the referral 
                    # is resolved as soon as the hook returns
                    #

                    phrase[hookType]


        ).then done, done

                #
                # done is promise resolve and reject handler
                #


    onTimeout:  (opts, control) -> 

        return (done, detail, inject) -> 

            if opts.context.handler?

                if typeof opts.context.handler.onTimeout == 'function'
            
                    return opts.context.handler.onTimeout done, detail, pushFn

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

            return done() unless typeof control.beforeAll == 'function'

            promise = deferral.optional

                resolver: 'done'
                context: if opts.context.global then null else this
                control.beforeAll

            promise().then -> 

                #
                # TODO: handle errors in hooks
                #

                done()

        


    beforeEach: (opts, control) -> 

        return (done, inject) -> 

            #
            # for phrase recursion and flow control
            # -------------------------------------
            # 
            # * PhraseStack controls the flow of the phrase recursion by pending
            #   the resolution of the parents async injector deferral until
            #   all it's child phrases are processed
            # 
            # * The async injector itself (set parallel: false) controls the flow
            #   through each child, not processing next until current has completed
            # 
            # * Throughout this procedure a phrase stack is pushed and popped
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

            #
            # for running each phrase's beforeEach hook
            # -----------------------------------------
            # 

            if opts.context.leafOnly

                # 
                # * in leafOnly mode the hooks are run from the stack upon
                #   encountering a leaf
                # 

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

                return

            return done() unless typeof control.beforeEach == 'function'

                #            
                # * otherwise the hooks are run inline at each phrase
                # * with or without resolver
                # * deferral.optional injects resolver if done is present 
                #   in control.beforeEach function
                #

            promise = deferral.optional

                resolver: 'done'
                context: if opts.context.global then null else this
                control.beforeEach

            promise().then -> 

                #
                # TODO: handle errors in hooks
                #

                done()


    afterEach: (opts, control) -> 

        return (done, inject) -> 

            element = opts.stack[ opts.stack.length - 1 ]
            target  = if opts.context.global then null else this

            sequence([

                    #
                ->  # when leafOnly mode, run hook stack if element is leaf
                    #
                    return unless element?
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


                    #
                ->  # run inline hook
                    # 
                    # * not leafOnly, hooks run around phrase call
                    #   and are not pended till leaf
                    #

                    return if opts.context.leafOnly
                    return unless typeof control.afterEach == 'function'
                    
                    promise = deferral.optional

                        resolver: 'done'
                        context: target
                        control.afterEach

                    promise()


            ]).then -> 

                #
                # TODO: handle errors in hooks
                #

                done()



    afterAll: (opts, control) -> 

        return (done, inject) -> 

            finished = -> 

                done()

                #
                # pend resolution of parent till after done()
                #

                process.nextTick -> 

                    #
                    # afterAll resolved the parent's injection deferral
                    # -------------------------------------------------
                    # 
                    # * this releases the flow onto the next phrase 
                    #   at the parent depth
                    #

                    if opts.stack.length > 0

                        parent = opts.stack[ opts.stack.length - 1 ]
                        return parent.defer.resolve()

                    #
                    # * there is no parent, resolve the master deferral if present
                    #
                    
                    opts.context.done() if typeof opts.context.done =='function'


            return finished() unless typeof control.afterAll == 'function'

            promise = deferral.optional

                resolver: 'done'
                context: if opts.context.global then null else this
                control.afterAll

            promise().then -> 

                #
                # TODO: handle errors in hooks
                #

                finished()



