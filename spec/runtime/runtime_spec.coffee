require('nez').realize 'Runtime', (Runtime, test, context, should) -> 

    context 'at startup', (it) ->

        it 'assembles a logger object', (done) -> 

            should.exist (new Runtime).logger 
            test done

        it 'defaults listen config', (done) -> 

            (new Runtime).listen.should.eql 

                adaptor: 'socket.io'
                iface: '127.0.0.1'
                port: null

            test done

        it 'defaults connect config', (done) -> 

            (new Runtime).connect.should.eql 

                adaptor: 'socket.io'
                uri: 'http://localhost:10101'

            test done
