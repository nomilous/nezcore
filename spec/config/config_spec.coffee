require('nez').realize 'Config', (Config, test, context) -> 

    context 'defaults', (it) -> 

        it 'defaults objective module to eo:dev', (done) -> 

            Config.get('objective').should.eql 

                module: 'eo'
                class: 'dev'

            test done

        it 'allows objective override from env', (done) ->

            process.env.NEZ_OBJECTIVE_MODULE = 'NEZ_OBJECTIVE_MODULE'
            process.env.NEZ_OBJECTIVE_CLASS = 'NEZ_OBJECTIVE_CLASS'
            Config.hup()

            Config.get('objective').should.eql 

                module: 'NEZ_OBJECTIVE_MODULE'
                class: 'NEZ_OBJECTIVE_CLASS'

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

