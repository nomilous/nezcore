{argsOf}   = require('also').util
{async}    = require('also').inject
LeafDetect = require './phrase_leaf_detect' 

#
# PhraseStack 
# ===========
# 
# TODO: ???????????
# 

module.exports = 

    create: (context, notice, realizerFn, tester) -> 

                                            #
                                            # TODO: tester not appropriate here
                                            #

        stack   = []

        context.isLeaf ||= LeafDetect.default

        #
        # when context.leafOnly == true a hook stack is accumulated
        # and only executed upon entering and exiting a leaf node
        #

        hooks = {}

        pushHook = (hookType, control) -> 

        runHooks = (hookType, control, done) -> 

            
            done()

        popHook = (hookType) -> 


        stacker = (elementName, control) -> 

            pushFn = async

                parallel: false
                timeout: control.timeout || 0

                error: (error) -> 

                    console.log error.stack

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

                    stack.push

                        element:    elementName
                        phrase:     inject.args[0]
                        defer:      inject.defer
                        queue:      inject.queue
                        current:    inject.current
                        beforeEach: control.beforeEach
                        afterEach:  control.afterEach
                        # fn:         inject.args[2]

                    if control.leafOnly 

                        pushHook 'beforeEach', control

                        context.isLeaf 

                            element: elementName
                            phrase: inject.args[0]
                            fn: inject.args[2]

                            (leaf) ->

                                if leaf

                                    #
                                    # set leaf so that afterEach does not need
                                    # to perform the same investigation
                                    #

                                    control.leaf = true

                                    console.log LEAF: 
                                        element: elementName
                                        phrase: inject.args[0]

                                    return runHooks 'beforeEach', control, done

                                done()


                    else if typeof control.beforeEach == 'function'

                        return control.beforeEach done unless control.global
                        return control.beforeEach.call null, done

                    else done()

                    

                afterEach: (done, inject) -> 

                    if inject.current.timeout

                        #
                        # pass to tester on element timeout
                        #

                        pushFn.timeout = true
                        tester pushFn if typeof tester == 'function'

                    element = stack.pop()

                    if element.queue.remaining == 0

                        #
                        # no further unprocessed phrases at the current depth
                        # 
                        # * resolve the parent (which is not a leaf node and 
                        #   therefore will receive no resolve call)
                        #

                        parent = stack[stack.length-1]
                        parent.defer.resolve() if parent?

                        unless parent?

                            #
                            # at root node, queue empty all done
                            #

                            if context.done? then context.done()
                            done()


                    if control.leaf

                        pushHook 'afterEach', control
                        return runHooks 'afterEach', control, done

                    else if typeof control.afterEach == 'function'

                        return control.afterEach done unless control.global
                        return control.afterEach.call null, done

                    done()


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
