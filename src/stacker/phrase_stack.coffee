{argsOf}         = require('also').util
{async}          = require('also').inject
{defer}          = require 'when'
sequence         = require 'when/sequence'
PhraseLeafDetect = require './phrase_leaf_detect'
PhraseInjector   = require './phrase_injector'

#
# PhraseStack 
# ===========
# 
# TODO: ???????????
# 

module.exports = 

    create: (context, notice, realizerFn) -> 

        stack   = []

        context.isLeaf ||= PhraseLeafDetect.default

        stacker = (elementName, control) -> 

            injectionOpts = 

                elementName: elementName
                context: context
                stack: stack

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


                beforeAll:  PhraseInjector.beforeAll  injectionOpts, control
                beforeEach: PhraseInjector.beforeEach injectionOpts, control
                
                afterAll:   PhraseInjector.afterAll   injectionOpts, control

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
                            PhraseInjector.runHooks 'afterEach', reversed, (result) ->

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
                                if parent?

                                    parent.defer.resolve()

                                else

                                    #
                                    # no parent, master resolve
                                    #

                                    context.done() if typeof context.done =='function'


                (phrase, nestedControl, fn) -> 

                    #
                    # call fn with nested element stacker
                    #

                    childElementName = argsOf( fn )[0]
                    # nestedControl.global = control.global
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
