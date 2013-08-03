PhraseStack      = require '../../lib/stacker/phrase_stack'
PhraseLeafDetect = require '../../lib/stacker/phrase_leaf_detect'
PhraseInjector   = require '../../lib/stacker/phrase_injector'
should           = require 'should'

describe 'PhraseInjector', -> 

    OPTS = undefined

    beforeEach ->

        OPTS = 
            stack: []
            context: {}

    xit 'creates before() and after() hook registers', (done) -> 

        before.toString().should.match /beforeHooks.each/
        after.toString().should.match /afterHooks.each/
        done()

    xcontext 'runHooks()', -> 

        it 'calls the resolver at arg2', (done) -> 

            PhraseInjector.runHooks 'beforeEach', [], -> done() 

        it 'calls each hook in the stack', (done) -> 

            RUNS = []    
            PhraseInjector.runHooks 'beforeEach', [

                { beforeEach: (done) -> RUNS.push 1; done() }
                { beforeEach: (done) -> RUNS.push 2; done() }
                { beforeEach: (done) -> RUNS.push 3; done() }

            ], -> 

                RUNS.should.eql [1,2,3]
                done()


    xcontext 'beforeAll()', -> 

        it 'returns a function', (done) -> 

            PhraseInjector.beforeAll().should.be.an.instanceof Function
            done()

        it 'returns a function that runs the registred beforeall hook', (done) -> 

            before all: -> done()
            hook = PhraseInjector.beforeAll OPTS, {}
            hook ->


        it 'running the function calls the resolver', (done) -> 

            hook = PhraseInjector.beforeAll OPTS, {}
            hook done

        context 'done is optional', ->

            it 'no resolver is injected into the hook if hook arg1 is not "done"', (done) -> 

                hook = PhraseInjector.beforeAll OPTS, beforeAll: -> 
                    should.not.exist arguments[0]
                    done()

                hook -> 

            it 'resolver is still called after the doneless hook', (done) -> 

                 hook = PhraseInjector.beforeAll OPTS, beforeAll: -> 
                 hook -> 
                    #
                    # hook still resolves
                    #
                    done()


            it 'a resolver is injected into the hook if hook arg signature contains "done"', (done) -> 

                before all: (done) -> 

                    should.exist arguments[0]
                    done.should.be.an.instanceof Function
                    done()

                hook = PhraseInjector.beforeAll OPTS, {}
                hook -> 

                    done()


        it 'running the function attaches registered hooks onto the control', (done) -> 

            control = {}

            beforeAll  = (done) -> done()
            beforeEach = (done) -> done()
            afterAll   = (done) -> done()
            afterEach  = (done) -> done()

            before 
                all:  beforeAll
                each: beforeEach

            after 
                all:  afterAll
                each: afterEach

            
            hook = PhraseInjector.beforeAll OPTS, control
            hook ->
            
            control.should.eql

                beforeEach: beforeEach
                beforeAll: beforeAll
                afterEach: afterEach
                afterAll: afterAll

            done()

        it 'preserves already defined control.beforeAll', (done) -> 

            before all: -> throw 'SHOULD NOT RUN'

            hook = PhraseInjector.beforeAll OPTS, 

                #
                # control alreaty has beforeAll defined
                #

                beforeAll: -> done()

            hook ->


        it 'running the function calls the assigned beforeAll hook', (done) -> 

            before all: -> done()
            hook = PhraseInjector.beforeAll OPTS, {}
            hook ->


        it 'running the function preserves scope into the call to beforeAll', (done) -> 

            obj = new Object property: 'VALUE'

            before all: -> 

                @property.should.equal 'VALUE'
                done()

            hook = PhraseInjector.beforeAll OPTS, {}

            hook.call obj, ->


        it 'running the function with control.global as true runs beforeAll on the global scope', (done) -> 

            obj = new Object property: 'VALUE'

            fn = -> 

                #
                # `this` is now obj
                #

                @property.should.equal 'VALUE'

                hook = PhraseInjector.beforeAll context: global: true, 

                    beforeAll: -> 

                        #
                        # `this` was reset to global
                        #

                        @process.title.should.equal 'node'
                        should.not.exist @property
                        done()

                hook ->

            #
            # call fn on obj
            #

            fn.call obj


    xcontext 'beforeEach()', -> 

        it 'returns a function that prepares the async injection', (done) -> 

            control = defer: "parent's async injection promise"

            hook = PhraseInjector.beforeEach OPTS, control

            #
            # also.inject.async injection context is passed as arg2 to the
            # hook handler
            #

            inject = 

                args: [

                    'phrase text'

                    (nested) -> 

                        #
                        # function that would contain child phrases
                        # 

                        'NESTED'  

                ]

                defer: "this phrase's async injection promise"

            hook (->

                #
                # it ensures injection args
                # -------------------------
                # 
                # 1. phrase text
                # 
                # 


                inject.args[0].should.equal 'phrase text'

                #
                # 2. config hash (defaulted if not present)
                # 
                #    * attached this injections promise to the 
                #      nestedControl object that is used to 
                #      create the child phrases of this phrase
                # 

                inject.args[1].should.eql defer: "this phrase's async injection promise"

                #
                # 3. function
                #
                #    * the function (as passed), that contains all child phrases
                # 

                inject.args[2].should.be.an.instanceof Function
                inject.args[2]().should.equal 'NESTED'
                done()

            ), inject


        it 'default arg3 to resolve the parent and pop the stack, if no args', (done) -> 

            #
            #   phrase 'phrase text', (done) -> 
            #               
            #               # 
            #       done()  # no args, resolves the parent's injection promise
            #               #          which leads to the processing of the 
            #               #          next phrase
            #               # 
            # 
            #   phrase 'next phrase text', (nested) -> 
            # 
            #       nested '...', (done) ->
            #

            POPPED     = false
            OPTS.stack = 
                push: -> 
                pop: -> POPPED = true
            control    = defer: resolve: -> 

                #
                # parent's injection promise is resolved
                # and stack is popped
                #

                POPPED.should.equal true
                done()


            inject  = args: []
            hook    = PhraseInjector.beforeEach OPTS, control

            hook (-> 

                #
                # make the call to arg3 `done()`
                # 

                inject.args[2]()

            ), inject


        it 'does something useful when called with one arg', (done) -> 

            inject = args: [ 'phrase text' ]
            hook = PhraseInjector.beforeEach OPTS, {}
            hook done, inject


        it 'pushes the stack', (done) -> 

            OPTS.stack = []
            OPTS.elementName = 'fridge'
            OPTS.context = {}
            beforeE = (done) -> done()
            afterE = ->

            inject = 
                args: [ 'is cold enough', -> ]
                defer:   'DEFERRAL'
                queue:   'QUEUE'
                current: 'CURRENT'

            hook = PhraseInjector.beforeEach OPTS, 

                beforeEach: beforeE
                afterEach: afterE

            hook (->

                OPTS.stack.should.eql [
                    element:    'fridge'
                    phrase:     'is cold enough'
                    defer:      'DEFERRAL'
                    queue:      'QUEUE'
                    current:    'CURRENT'
                    beforeEach: beforeE
                    afterEach:  afterE

                ]
                done()

            ), inject


        it 'tests for leaf node if leafOnly is enabled and flags element as leaf', (done) -> 

            OPTS.stack = []
            OPTS.elementName = 'can'
            OPTS.context = leafOnly: true
            inject = args: [ 

                'arrange flowers', (done) -> 

                    #
                    # this function is sampled as a potential leaf node
                    #

                            #
                    done()  # and this would make it one
                            # 
            
            ]

            hook = PhraseInjector.beforeEach OPTS, {}

            OPTS.context.isLeaf = (params, isLeaf) -> 

                params.should.eql 

                    element: 'can'
                    phrase: 'arrange flowers'
                    fn: inject.args[2]

                #
                # make it a leaf
                #

                isLeaf true
            

            hook (->

                OPTS.stack[0].leaf.should.equal true
                done()

            ), inject


        it 'calls runHooks if leafMode and a leaf is detected', (done) -> 

            OPTS.stack = []
            OPTS.elementName = 'switches'
            OPTS.context = leafOnly: true
            OPTS.context.isLeaf = (params, isLeaf) -> isLeaf true

            inject = args: [ 

                    'switch1.cabinet03.container023.local', (done, instance) -> 

                        notice instance.status()
                        done()
                            
                ]

            hook = PhraseInjector.beforeEach OPTS, {}

            PhraseInjector.runHooks = (hookType, stack, resolver) -> 

                hookType.should.equal 'beforeEach'
                stack.should.equal OPTS.stack
                done()

            hook (->), inject


        it 'does not call runHooks if leafMode and not a leaf', (done) -> 

            OPTS.stack = []
            OPTS.elementName = 'services'
            OPTS.context = leafOnly: true
            OPTS.context.isLeaf = (params, isLeaf) -> 

                #
                # not a leaf
                #

                isLeaf false

            inject = args: [ 

                'switch fabric', (switches, manifest) ->

                    manifest( /switch\s*\.dc\.local/ ).then (list) ->

                        for hostname in list 

                            switches hostname, (done, switchInstance) -> 

                                notice.info switchInstance.status()
                                done()
                            
                ]

            hook = PhraseInjector.beforeEach OPTS, {}

            PhraseInjector.runHooks = (hookType, stack, resolver) -> 

                throw 'SHOULD NOT RUN'

            hook done, inject


        it 'runs the hook if not leaf mode', (done) -> 

            
            OPTS.elementName = 'it'
            OPTS.context = {}
            inject = args: [

                'does something', (done) -> done()

                ]
            hook = PhraseInjector.beforeEach OPTS, 

                beforeEach: -> done()

            hook (->), inject

        it 'preserves scope when running inline hooks', (done) -> 

            OPTS.context = {}
            OPTS.stack   = []

            obj = new Object

                property: 'VALUE'
                hook: PhraseInjector.beforeEach OPTS, beforeEach: -> 

                    @property.should.equal 'VALUE'
                    done() 

            obj.hook (->), args: []


    xcontext 'afterEach()', -> 

        it 'returns a function that calls the resolver', (done) -> 

            OPTS.stack = []
            hook = PhraseInjector.afterEach OPTS, {}
            hook (->
                done()
            ), {}


        it 'does not call runHooks if top element in stack is not leaf', (done) -> 

            hook = PhraseInjector.afterEach OPTS, {}
            OPTS.stack = [
                {leaf: false, queue: remaining: 1}
            ]
            RAN = false
            PhraseInjector.runHooks = (hookType, stack, done) -> 
                RAN = true
                done()

            hook (->
                RAN.should.equal false
                done()
            ), {}


        it 'calls runHooks if top element is leaf', (done) -> 

            hook = PhraseInjector.afterEach OPTS, {}
            OPTS.stack = [
                {leaf: true}
            ]
            PhraseInjector.runHooks = -> done()

            hook (-> ), {}


        it 'runs hooks in reverse order', (done) -> 

            hook = PhraseInjector.afterEach OPTS, {}
            OPTS.stack = [
                { depth: 0 }
                { depth: 1 }
                { depth: 2 }
                { depth: 3 }
                { depth: 4, leaf: true}
            ]
            PhraseInjector.runHooks = (hookType, stack, otherDone) -> 

                stack.should.eql [ 
                    { depth: 4, leaf: true }
                    { depth: 3 }
                    { depth: 2 }
                    { depth: 1 }
                    { depth: 0 } 
                ]
                done()

            hook (->), {}


        it 'pops the stack after running hooks and the stack is not still reversed', (done) -> 

            hook = PhraseInjector.afterEach OPTS, {}
            OPTS.stack = [
                { depth: 0 }
                { depth: 1 }
                { depth: 2 }
                { depth: 3 }
                { depth: 4, leaf: true, queue: remaining: 1}
            ]
            PhraseInjector.runHooks = (hookType, stack, done) -> 

                stack.should.eql [ 
                    { depth: 4, leaf: true, queue: remaining: 1}
                    { depth: 3 }
                    { depth: 2 }
                    { depth: 1 }
                    { depth: 0 } 
                ]
                done()

            hook (->

                OPTS.stack.should.eql [ 
                    { depth: 0 }
                    { depth: 1 }
                    { depth: 2 }
                    { depth: 3 } 
                ]
                done()

            ), {}

        it 'runs inline afterEach hooks', (done) -> 


            OPTS.stack = [{ depth: 0, queue: remaining: 1}]
            OPTS.context = leafOnly: false
            RAN  = false
            hook = PhraseInjector.afterEach OPTS, afterEach: (done) -> RAN = true; done()
            hook (->

                RAN.should.equal true
                done()

            ), {}


        it 'does not run inline hooks if leafOnly mode', (done) -> 

            OPTS.stack   = [queue: remaining: 1]
            OPTS.context = leafOnly: true
            RAN  = false
            hook = PhraseInjector.afterEach OPTS, afterEach: (done) -> RAN = true; done()
            hook (->

                RAN.should.equal false
                done()

            ), {}

        it 'preserves scope when running inline hooks', (done) -> 

            OPTS.context = {}
            OPTS.stack   = [queue: remaining: 1]

            obj = new Object

                property: 'VALUE'
                hook: PhraseInjector.afterEach OPTS, afterEach: -> 

                    @property.should.equal 'VALUE'
                    done() 

            obj.hook (->), args: []


        it 'resets scope to global if context.global is set', (done) -> 

            OPTS.context = global: true
            OPTS.stack   = [queue: remaining: 1]

            obj = new Object

                property: 'VALUE'
                hook: PhraseInjector.afterEach OPTS, afterEach: -> 

                    @process.title.should.equal 'node'
                    done() 

            obj.hook (->), args: []


        it 'does not resolve the parent phrase if unprocessed nodes (peers) exist on the current phrase', (done) ->

            RAN = false
            parentPhrase  = defer: resolve: -> RAN = true
            currentPhrase = queue: remaining: 1
            OPTS.stack    = [ parentPhrase, currentPhrase ]

            hook = PhraseInjector.afterEach OPTS, {}
            hook -> 

                #
                # parent resolver would be on nextTick
                # (need to test after that)
                #

                setTimeout (-> 
                    RAN.should.equal false
                    done()
                ), 10


        it 'resolves the parent phrase if no unprocessed nodes (peers) exist on the current phrase', (done) ->

            RAN = false
            parentPhrase  = defer: resolve: -> RAN = true
            currentPhrase = queue: remaining: 0
            OPTS.stack    = [ parentPhrase, currentPhrase ]

            PhraseInjector.afterEach( OPTS, {} ) -> setTimeout (-> 

                RAN.should.equal true
                done()

            ), 10
        

        it 'resolves the master promise if current phrase is the root and has no further unprocessed peers', (done) -> 

            rootPhrase = queue: remaining: 0
            OPTS.stack = [rootPhrase]
            OPTS.context.done = -> 

                #
                # master promise is resolved
                #

                done()

            PhraseInjector.afterEach( OPTS, {} ) ->



    context 'afterAll()', -> 

        it 'returns a function that runs the registred afterall hook', (done) -> 

            hook = PhraseInjector.afterAll OPTS, afterAll: -> done()
            hook -> 

        it 'runs the resolver', (done) -> 

            hook = PhraseInjector.afterAll OPTS, afterAll: ->
            hook -> done()

        it 'preserves scope when running inline hooks', (done) -> 

            OPTS.context = {}
            OPTS.stack   = []

            obj = new Object

                property: 'VALUE'
                hook: PhraseInjector.afterAll OPTS, afterAll: -> 

                    @property.should.equal 'VALUE'
                    done() 

            obj.hook (->), args: []



