PhraseStack      = require '../../lib/stacker/phrase_stack'
PhraseLeafDetect = require '../../lib/stacker/phrase_leaf_detect'
PhraseHook       = require '../../lib/stacker/phrase_hook'
should           = require 'should'

describe 'PhraseHook', -> 

    OPTS = undefined

    beforeEach ->

        OPTS = {}

    xit 'creates before() and after() hook registers', (done) -> 

        before.toString().should.match /beforeHooks.each/
        after.toString().should.match /afterHooks.each/
        done()


    xcontext 'beforeAll()', -> 

        it 'returns a function', (done) -> 

            PhraseHook.beforeAll().should.be.an.instanceof Function
            done()

        it 'returns a function that runs the registred beforeall hook', (done) -> 

            before all: -> done()
            hook = PhraseHook.beforeAll OPTS, {}
            hook ->


        it 'running the function calls the resolver', (done) -> 

            hook = PhraseHook.beforeAll OPTS, {}
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

            
            hook = PhraseHook.beforeAll OPTS, control
            hook ->
            
            control.should.eql

                beforeEach: beforeEach
                beforeAll: beforeAll
                afterEach: afterEach
                afterAll: afterAll

            done()

        it 'preserves already defined control.beforeAll', (done) -> 

            before all: -> throw 'SHOULD NOT RUN'

            hook = PhraseHook.beforeAll OPTS, 

                #
                # control alreaty has beforeAll defined
                #

                beforeAll: -> done()

            hook ->


        it 'running the function calls the assigned beforeAll hook', (done) -> 

            before all: -> done()
            hook = PhraseHook.beforeAll OPTS, {}
            hook ->


        it 'running the function preserves scope into the call to beforeAll', (done) -> 

            obj = new Object property: 'VALUE'

            before all: -> 

                @property.should.equal 'VALUE'
                done()

            hook = PhraseHook.beforeAll OPTS, {}

            hook.call obj, ->


        it 'running the function with control.global as true runs beforeAll on the global scope', (done) -> 

            obj = new Object property: 'VALUE'

            fn = -> 

                #
                # `this` is now obj
                #

                @property.should.equal 'VALUE'

                hook = PhraseHook.beforeAll global: true, 

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

        xit 'returns a function that prepares the async injection', (done) -> 

            control = defer: "parent's async injection promise"

            hook = PhraseHook.beforeEach OPTS, control

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


        xit 'default arg3 to resolve the parent and pop the stack, if no args', (done) -> 

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
            OPTS.stack = pop: -> POPPED = true
            control    = defer: resolve: -> 

                #
                # parent's injection promise is resolved
                # and stack is popped
                #

                POPPED.should.equal true
                done()


            inject  = args: []
            hook    = PhraseHook.beforeEach OPTS, control

            hook (-> 

                #
                # make the call to arg3 `done()`
                # 

                inject.args[2]()

            ), inject


        it 'does something useful when called with one arg', (done) -> 

            inject = args: [ 'phrase text' ]
            hook = PhraseHook.beforeEach OPTS, {}
            hook done, inject




    xcontext 'afterAll()', -> 

        it 'returns a function that runs the registred afterall hook', (done) -> 

            hook = PhraseHook.afterAll OPTS, afterAll: -> done()
            hook -> 

        it 'runs the resolver', (done) -> 

            hook = PhraseHook.afterAll OPTS, {}
            hook done

