require('nez').realize 'Checksum', (Checksum, test, context, fs) -> 

    context 'file( filename )', (it) ->

        it 'generates an md5 sum', (done) ->

            fs.readFileSync = -> 'file content'
            Checksum.file( __filename ).should.equal 'd10b4c3ff123b26dc068d43a8bef2d23'
            test done
