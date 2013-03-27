require('nez').realize 'Config', (Config, test, context) -> 

    context 'from file', (it) -> 

        it 'loads', (done, fs) ->  

            original = fs.readFileSync

            fs.readFileSync = (filename) ->

                filename.should.equal 'FILENAME'
                fs.readFileSync = original
                test done


            Config.load file: 'FILENAME'
