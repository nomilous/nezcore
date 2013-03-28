require('nez').realize 'Config', (Config, test, context) -> 

    context 'defaults', (it) -> 

        it 'defaults objective module to eo', (done) -> 

            Config.get('objective').should.eql module: 'eo'
            test done

        it 'allows override from env.NEZ_OBJECTIVE_PLUGIN', (done) ->

            process.env.NEZ_PLUGIN_OBJECTIVE = 'NEZ_OBJECTIVE_PLUGIN'
            Config.hup()
            Config.get('objective').should.eql module: 'NEZ_OBJECTIVE_PLUGIN'
            test done


    context 'from file', (it) -> 

        it 'loads', (done, fs) ->  

            original = fs.readFileSync

            fs.readFileSync = (filename) ->

                fs.readFileSync = original
                filename.should.equal 'FILENAME'
                test done

            Config.load file: 'FILENAME'
