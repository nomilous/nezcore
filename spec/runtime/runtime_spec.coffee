require('nez').realize 'Runtime', (Runtime, test, context, should) -> 

    context 'at startup', (it) ->

        it 'assembles a logger object', (done) -> 

            should.exist (new Runtime).logger 
            test done

