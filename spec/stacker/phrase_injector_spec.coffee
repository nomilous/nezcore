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

    it 'creates before() and after() hook registers', (done) -> 

        before.toString().should.match /beforeHooks.each/
        after.toString().should.match /afterHooks.each/
        done()

    context 'runHooks()', -> 

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


    context 'beforeAll()', -> 

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

                hook = PhraseInjector.beforeAll global: true, 

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


    context 'beforeEach()', -> 

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

    context 'afterEach()', -> 

        it 'returns a function that calls the resolver', (done) -> 

            hook = PhraseInjector.afterEach OPTS, {}
            hook done, {}


    context 'afterAll()', -> 

        it 'returns a function that runs the registred afterall hook', (done) -> 

            hook = PhraseInjector.afterAll OPTS, afterAll: -> done()
            hook -> 

        it 'runs the resolver', (done) -> 

            hook = PhraseInjector.afterAll OPTS, {}
            hook done

