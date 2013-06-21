require('nez').realize 'Directory', (Directory, test, context) -> 

    context 'monitors directory for changes', (it) ->

        it 'calls with ENOENT', (done) -> 

            Directory '/path', (error, callback) -> 

                error.code.should.equal 'ENOENT'
                error.message.should.match /no such file or directory/
                test done
