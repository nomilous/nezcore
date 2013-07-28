require('nez').realize 'Js', (Js, test, context, should) -> 

    {fn}      = Js
    {compile} = require 'coffee-script'

    context 'fn.parser()', (it) -> 

        parser = fn.parser()

        it 'returns an event emitter', (done) -> 

            parser.should.be.an.instanceof require('events').EventEmitter
            test done

        it 'emits end on no js', (done) -> 

            parser.once 'end', -> test done
            parser.parse ''

        it 'emits parsed function closure heap', (done) -> 

            parser.once 'closure', (heap) -> 

                heap[0].signature.should.eql []
                heap[0].variables.should.eql []
                heap[0].statements.should.eql ['return function()']
                heap[0].body.should.eql 'return function() {};'

                heap[1].signature.should.eql []
                heap[1].variables.should.eql []
                heap[1].statements.should.eql []
                heap[1].body.should.eql ''
                test done

            parser.parse compile '-> ->', bare: true


        it 'parses function signature', (done) -> 

            parser.once 'closure', (heap) -> 

                heap[1].signature.should.eql ['arg1', 'arg2']
                test done

            parser.parse compile '(arg1, arg2) ->'


        it 'parses function variables', (done) -> 

            parser.once 'closure', (heap) -> 

                heap[1].variables.should.eql ['one', 'three', 'two']
                heap[2].variables.should.eql ['five']
                test done

            parser.parse compile """ 

                -> 
                    one   = 3 
                    two   = 2 
                    three = (four) -> 

                        five = 4

            """

        it 'parses statements', (done) -> 

            parser.once 'closure', (heap) -> 

                heap[1].statements.should.eql [
                    'one = 3'
                    'two = 2'
                    'return three = function(four)'
                ]
                heap[2].statements.should.eql [
                    'return five = 4'
                ]
                test done

            parser.parse compile """ 

                -> 
                    one   = 3 
                    two   = 2 
                    three = (four) -> 

                        five = 4

            """

        it 'emits the closure at every leaf', (done) -> 

            parser = fn.parser()

            COUNT  = 0

            parser.on 'closure', (heap) -> 

                COUNT++

            parser.on 'end', ->

                COUNT.should.equal 2
                test done

            parser.parse compile """ 

                context 'context title', (it) -> 

                    it 'does a something', (done) -> 

                        done()

                    it 'does a something else', (done) -> 

                        done()


            """

