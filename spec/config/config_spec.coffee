require('nez').realize 'Config', (Config, test, context) -> 

    context 'from file', (it) -> 

        it 'loads', (done, fs) ->  

            original = fs.readFileSync

            fs.readFileSync = (filename) ->

                fs.readFileSync = original
                filename.should.equal 'FILENAME'
                test done

            Config.load file: 'FILENAME'
