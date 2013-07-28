PhraseStack = require '../../lib/stacker/phrase_stack'
should      = require 'should'

describe 'PhraseStack', -> 

    CONTEXT  = title: 'Thing'
    NOTICE   = {}
    REALIZER = (root, test) -> 

    context 'create()', ->

        it 'is a function', (done) -> 

            PhraseStack.create.should.be.an.instanceof Function
            done()

        it 'returns a function', (done) -> 

            stacker = PhraseStack.create CONTEXT, NOTICE, REALIZER
            stacker.should.be.an.instanceof Function
            done()

    context 'is used to build a phrase stack', -> 

        it 'exposes the stack and top properties', (done) -> 

            stacker = PhraseStack.create CONTEXT, NOTICE, REALIZER
            stacker 'phrase', (nested) -> 

                nested.stack.should.be.an.instanceof Array
                nested.top.should.equal nested.stack[nested.stack.length-1]
                done()

        it 'pushes the stack', (done) -> 

            stacker = PhraseStack.create CONTEXT, NOTICE, REALIZER

            stacker.stack.length.should.equal 0
            stacker 'outer phrase', CONTROL_OPTS: 'VALUE', (neSTed) ->

                stacker.stack.length.should.equal 1
                neSTed 'inner phrase', (end) -> 

                    stacker.stack.length.should.equal 2
                    node = stacker.stack[1]
                    node.element.should.equal 'neSTed'
                    node.phrase.should.equal 'inner phrase'

                    # #
                    # # stack element contains parent's control opts
                    # #
                    # node.control.CONTROL_OPTS.should.equal 'VALUE'

                    # #
                    # # stack element contains reference to 'this' function
                    # #
                    # node.fn.toString().should.match /node\.fn\.toString\(\)\.should\.match/
                    done()


        it 'pops the stack', (done) -> 

            stacker = PhraseStack.create CONTEXT, NOTICE, REALIZER

            stacker 'first root', (outer) -> 

                outer 'outer phrase 1', (inner) -> 

                    inner 'inner phrase 1', (stop) -> 

                        stop.stack.length.should.equal 3
                        #console.log stop.stack[stop.stack.length-1].element, stop.stack.length
                        stop()

                    inner 'inner phrase 2', (deepest) -> 
                        
                        deepest 'deepest phrase1', (stop) -> 

                            #console.log stop.stack[stop.stack.length-1].element, stop.stack.length
                            stop.stack.length.should.equal 4
                            stop()


                outer 'outer phrase 2', (stop) -> 

                    stop.stack.length.should.equal 2
                    #console.log stop.stack[stop.stack.length-1].element, stop.stack.length
                    stop()

            stacker 'second root', (stop) -> 

                stop.stack.length.should.equal 1
                #console.log stop.stack[stop.stack.length-1].element, stop.stack.length
                stop()

                done()

    context 'hooks', -> 

        it 'runs before and after hooks inline', (done) -> 

            stacker = PhraseStack.create CONTEXT, NOTICE, REALIZER

            HOOKS = []

            stacker( 'outer phrase',

                beforeAll:  (done) -> HOOKS.push 'BEFORE ALL';  done()
                beforeEach: (done) -> HOOKS.push 'BEFORE EACH'; done()
                afterEach:  (done) -> HOOKS.push 'AFTER EACH';  done()
                afterAll:   (done) -> HOOKS.push 'AFTER ALL';   done()

                (nested) -> 

                    nested 'inner phrase 1', (end) -> 

                        HOOKS.should.eql ['BEFORE ALL', 'BEFORE EACH']
                        end()

                    nested 'inner phrase 2', (end) -> 

                        HOOKS.should.eql ['BEFORE ALL', 'BEFORE EACH', 'AFTER EACH', 'BEFORE EACH' ]
                        end()

            ).then -> 

                HOOKS.should.eql ['BEFORE ALL', 'BEFORE EACH', 'AFTER EACH', 'BEFORE EACH', 'AFTER EACH', 'AFTER ALL']
                done()


        it 'is supports a leafOnly mode that tests for leaf on every phrase', (done) -> 

            COUNT   = 0
            stacker = PhraseStack.create { 

                leafOnly: true

                #
                # override default leaf test
                #

                isLeaf: (params, isLeaf) -> 

                    COUNT++
                    isLeaf true

            }, NOTICE, REALIZER


            stacker 'outer phrase', (nested) -> 

                nested 'inner phrase 1', (done) -> 

                    done()

                nested 'inner phrase 2', (done) -> 

                    done()

            .then -> 

                COUNT.should.equal 5
                done()

        it 'uses a default leaf detector', (done) -> 

            phraseFn = ->

            require('../../lib/stacker/phrase_leaf_detect').default = (params, isLeaf) -> 

                params.should.eql 

                    element: 'root'
                    phrase:  'outer phrase'
                    fn:      phraseFn

                done()
                
            stacker = PhraseStack.create leafOnly: true, NOTICE, REALIZER
            stacker 'outer phrase', phraseFn


        xit 'can be set to only run beforeEach and afterEach hooks upon encountering a leaf node', (done) -> 

            
            #
            # IMPORTANT
            # 
            # * Set `leafOnly: true` on context to enable only running the accumulated beforeEach
            #   and afterEach hooks upon encountering a leaf node.
            # 
            # * This will repeat the hooks ancestrally. 
            # 
            #   ie. the entire stack of accumulated beforeEach and afterEach hooks runs before
            #       and after the execution of a leaf node
            # 
            # * This does not affect beforeAll and afterAll - these hooks are run before and after
            #   the subtree they surround at the time the walker arrives and departs the subtree.
            #

            HOOKS = {}

            stacker = PhraseStack.create {

                leafOnly: true

            }, NOTICE, REALIZER

            stacker 'outer phrase',

                beforeEach: (done) -> 

                    console.log 'outer before each'
                    HOOKS[ 'outer before each'] ||= 0
                    HOOKS[ 'outer before each']++
                    done()

                afterEach: (done) -> 

                    console.log 'outer after each'
                    HOOKS[ 'outer after each'] ||= 0
                    HOOKS[ 'outer after each']++
                    done()

                (nested) -> 

                    #setTimeout (-> nested()), 100

                    #nested()

                    nested 'LEAF NODE 1', (done) -> 

                        console.log RUN: 'LEAF NODE 1'

                        done()

                    # nested 'nested phrase'

                    #     beforeEach: (done) -> 

                    #         console.log 'nested before each'
                    #         HOOKS[ 'nested before each'] ||= 0
                    #         HOOKS[ 'nested before each']++
                    #         done()

                    #     afterEach: (done) -> 

                    #         console.log 'nested after each'
                    #         HOOKS[ 'nested after each'] ||= 0
                    #         HOOKS[ 'nested after each']++
                    #         done()

                    #     (deeper) -> 

                    #         deeper 'LEAF NODE 2', (done) -> 

                    #             console.log RUN: 'LEAF NODE 2'
                    #             done() 

                    #         deeper 'LEAF NODE 3', (done) -> 

                    #             console.log RUN: 'LEAF NODE 3'
                    #             done() 

            .then -> 

                console.log HOOKS
                HOOKS.should.eql 

                    'outer before each':  3  #  3 leaf nodes exist inside the outer phrase
                    'nested before each': 2  #  2 leaf nodes exist inside 
                    'nested after each':  2  #  
                    'outer after each':   3  # 

                done()


        xit 'can optionally enforce global scope', (done) -> 

            done 'not'

            
            stacker   = PhraseStack.create {     global: true     }, NOTICE, REALIZER

            @variable = {}
            @count    = 0

            stacker( 'outer phrase', 

                beforeAll:  (done) -> @variable.beforeAll  = ++@count; done()
                beforeEach: (done) -> @variable.beforeEach = ++@count; done()
                afterEach:  (done) -> @variable.afterEach  = ++@count; done()
                afterAll:   (done) -> @variable.afterAll   = ++@count; done()

                (nested) -> 

                    nested 'inner phrase', (next) -> 

                        #console.log @variable

                        @variable.should.eql 

                            beforeAll:  1
                            beforeEach: 2

                        next()
                    
            ).then -> 

                #console.log @variable

                @variable.should.eql

                    beforeAll:  1
                    beforeEach: 2
                    afterEach:  3
                    afterAll:   4

                done()


    context 'timeout', (it) -> 

        # it 'can be assigned', (done) -> 

        #     stacker = Stack.create timeout: 10, NOTICE, REALIZER, (element) -> 

        #         element.timeout.should.equal true
        #         test done

        #     stacker 'phrase', (end) -> 


        # it 'runs on hooks', (done) -> 

        #     throw 'pending'


