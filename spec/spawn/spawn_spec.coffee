require('nez').realize 'Spawn', (Spawn, test, context) -> 

    context 'in CONTEXT', (does) ->

        does 'an EXPECTATION', (done) ->

            test done
