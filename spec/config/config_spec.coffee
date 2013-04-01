require('nez').realize 'Config', (Config, test, context) -> 

    context 'for the time being it', (defaults) ->

        defaults 'secret', (done) ->  

            Config.get('secret').should.equal 'SEEKRIT'
            test done

        defaults 'home', (done) ->  

            Config.get('home').should.equal 'http://localhost:10101'
            test done

        defaults 'adaptor', (done) ->  

            Config.get('adaptor').should.equal 'socket.io'
            test done
        

    context 'from file', (it) -> 

        it 'loads', (done, fs) ->  

            original = fs.readFileSync

            fs.readFileSync = (filename) ->

                fs.readFileSync = original
                filename.should.equal 'FILENAME'
                test done

            Config.load file: 'FILENAME'
            

