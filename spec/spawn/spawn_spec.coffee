require('nez').realize 'Spawn', (Spawn, test, it) -> 

    it 'spawns a child process with the coffee interpreter', (done) -> 
        
        Spawn 

            arguments: ['res/test.coffee']

            (error, child) -> 

                child.stdout.on 'data', (data) -> 

                    if data.toString().match(/OK/)? 

                        test done
                        

    it 'inherits parents env', (done) -> 

        process.env['VARIABLE'] = 'VALUE'

        Spawn

            arguments: ['res/test.coffee']        

            (error, child) -> 

                child.stdout.on 'data', (data) -> 

                    if data.toString().match(/VALUE/)?

                         test done

