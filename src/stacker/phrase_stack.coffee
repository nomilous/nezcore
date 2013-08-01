{argsOf}   = require('also').util
{async}    = require('also').inject
{defer}    = require 'when'
sequence   = require 'when/sequence'
LeafDetect = require './phrase_leaf_detect' 

#
# PhraseStack 
# ===========
# 
# TODO: ???????????
# 

if typeof Object.prototype.before == 'undefined'
    Object.defineProperty Object.prototype, 'before',
        get: -> (opts) -> console.log opts
        enumerable: false

if typeof Object.prototype.after == 'undefined'
    Object.defineProperty Object.prototype, 'after',
        get: -> (opts) -> console.log opts
        enumerable: false


module.exports = 

    create: (context, notice, realizerFn) -> 

        stack   = []

        context.isLeaf ||= LeafDetect.default

        runHooks = (hookType, stack, done) -> 

            #
            # context.leafOnly was set true
            # -----------------------------
            # 
            # In this mode the beforeEach and afterEach hooks are not run inline 
            # around each phrase boundry, but instead, upon detecting a leaf, the 
            # entire stack is traversed to run these hook before and after 
            # the phrase is executed.
            #


            # str = (for phrase in stack
            #     "[#{phrase.element}] #{phrase.phrase}"
            # ).join ' '
            # console.log '\nRUN', hookType, 'for', str


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


        stacker = (elementName, control) -> 

            pushFn = async

                parallel: false
                timeout: control.timeout || 0

                onError: (error) -> 

                    console.log error.stack

                onTimeout: (done, detail, inject) -> 

                    if context.handler?

                        if typeof context.handler.onTimeout == 'function'
                    
                            return context.handler.onTimeout done, detail, pushFn

                    done()

                beforeAll: (done) -> 

                    if typeof control.beforeAll == 'function'

                        return control.beforeAll done unless control.global
                        return control.beforeAll.call null, done

                    done()

                beforeEach: (done, inject) -> 

                    #
                    # ensure injection of (phrase, control, fn)
                    #

                    unless typeof inject.args[2] == 'function'

                        inject.args[2] = inject.args[1] || -> 

                            #
                            # make optional: "auto" resolve
                            #

                            control.defer.resolve()
                            stack.pop()

                        inject.args[1] = {}

                    inject.args[1].defer = inject.defer

                    stack.push element = 

                        element:    elementName
                        phrase:     inject.args[0]
                        defer:      inject.defer
                        queue:      inject.queue
                        current:    inject.current
                        # fn:         inject.args[2]

                        #
                        # before and afterEach hooks into the stack
                        # (default if undefined)
                        #

                        beforeEach: control.beforeEach || (done) -> done()
                        afterEach:  control.afterEach  || (done) -> done()
                        

                    if control.leafOnly 

                        context.isLeaf 

                            element: elementName
                            phrase: inject.args[0]
                            fn: inject.args[2]

                            (leaf) ->

                                if leaf

                                    #
                                    # flag element as leaf so that afterEach does not need
                                    # to perform the same investigation
                                    #

                                    element.leaf = true
                                    return runHooks 'beforeEach', stack, done

                                done()

                    else if typeof control.beforeEach == 'function'

                        return control.beforeEach done unless control.global
                        return control.beforeEach.call null, done

                    else done()

                    

                afterEach: (done, inject) -> 

                    element = stack[stack.length - 1]

                    sequence([

                        #
                        # leafOnly mode, run hooks if leaf
                        #

                        -> 

                            return unless element.leaf
                            step = defer()

                            #
                            # afterEach hooks run in reversed stack order
                            # 

                            reversed = []
                            reversed.unshift phrase for phrase in stack
                            runHooks 'afterEach', reversed, (result) ->

                                # 
                                # TODO: handle error in hook
                                # 
                                # return action.reject result if result instanceof Error
                                # cannot reject because entire sequence must run...
                                # 

                                step.resolve result

                            step.promise

                        #
                        # pop the stack
                        #

                        -> 

                            stack.pop()

                        #
                        # run non leafOnly hooks
                        #

                        -> 

                            return if control.leafOnly
                            #return if element.leaf
                            return unless typeof control.afterEach == 'function'

                            step = defer()
                            if control.global
                                return control.afterEach (result) -> step.resolve result
                            return control.afterEach.call null, (result) -> step.resolve result

                            step.promise


                    ]).then -> 

                        done()

                        #
                        # resolve parent if necessary 
                        # 

                        if element.queue.remaining == 0

                            process.nextTick ->

                                #
                                # no further unprocessed phrases at the current depth
                                # 
                                # * resolve the parent (which is not a leaf node and 
                                #   therefore will receive no resolve call)
                                #

                                parent = stack[stack.length-1]
                                parent.defer.resolve() if parent?





                afterAll: (done, inject) -> 

                    if typeof control.afterAll == 'function'

                        return control.afterAll done unless control.global
                        return control.afterAll.call null, done

                    done()

                (phrase, nestedControl, fn) -> 

                    #
                    # call fn with nested element stacker
                    #

                    childElementName = argsOf( fn )[0]
                    nestedControl.global = control.global
                    nestedControl.leafOnly = control.leafOnly
                    fn stacker childElementName, nestedControl


            Object.defineProperty pushFn, 'stack', 

                get: -> stack
                enumerable: false

            Object.defineProperty pushFn, 'top', 

                get: -> stack[stack.length - 1]
                enumerable: false


            return pushFn

        #
        # return root element named from arg1 of the realizerFn
        #

        return stacker argsOf( realizerFn )[0], context
