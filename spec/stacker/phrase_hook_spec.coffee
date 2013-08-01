PhraseStack      = require '../../lib/stacker/phrase_stack'
PhraseLeafDetect = require '../../lib/stacker/phrase_leaf_detect'
PhraseHook       = require '../../lib/stacker/phrase_hook'
should           = require 'should'

describe 'PhraseHook', -> 

    OPTS = {}

    it 'creates before() and after() hook registers', (done) -> 

        before.toString().should.match /beforeHooks.each/
        after.toString().should.match /afterHooks.each/
        done()


    context 'beforeAll()', -> 

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


    context 'afterAll()', -> 

        it 'returns a function that runs the registred afterall hook', (done) -> 

            hook = PhraseHook.afterAll OPTS, afterAll: -> done()
            hook -> 

        it 'runs the resolver', (done) -> 

            hook = PhraseHook.afterAll OPTS, {}
            hook done

