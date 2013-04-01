require('nez').realize 'Config', (Config, test, context) -> 

    context 'defaults secret for the time being', (done) -> 

        Config.get('secret').should.equal 'SEEKRIT'
        test done
        

    context 'from file', (it) -> 

        it 'loads', (done, fs) ->  

            original = fs.readFileSync

            fs.readFileSync = (filename) ->

                fs.readFileSync = original
                filename.should.equal 'FILENAME'
                test done

            Config.load file: 'FILENAME'
            1.should.equal 'TODO: load config from file'

