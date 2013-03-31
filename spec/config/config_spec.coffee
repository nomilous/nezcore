require('nez').realize 'Config', (Config, test, context) -> 

    context 'defaults', (it) -> 

        it 'defaults objective module to eo:Develop', (done) -> 

            Config.get('objective').should.eql 

                _class: 'eo:Develop'

            test done

        it 'allows objective override from env', (done) ->

            process.env.NEZ_OBJECTIVE = 'module:Class'
            Config.hup()

            Config.get('objective').should.eql 

                _class: 'module:Class'

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

