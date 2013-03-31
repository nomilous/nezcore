require('nez').realize 'Config', (Config, test, context) -> 

    context 'defaults', (it) -> 

        it 'defaults objective implementation to eo:Develop', (done) -> 

            Config.get('objective').should.eql 

                _class: 'eo:Develop'

            test done

        it 'defaults realization implementation to ipso:SpecRun', (done) -> 

            Config.get('realizer').should.eql 

                _class: 'ipso:SpecRun'

            test done

        it 'allows override from env', (done) ->

            process.env.NEZ_OBJECTIVE = 'Monitor:HostOk'
            process.env.NEZ_REALZER   = 'Ubuntu:V_12_04_LTS'

            Config.hup()

            Config.get( 'objective' ).should.eql _class: 'Monitor:HostOk'
            Config.get( 'realizer'  ).should.eql _class: 'Ubuntu:V_12_04_LTS'

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

