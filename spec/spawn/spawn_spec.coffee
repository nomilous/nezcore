require('nez').realize 'Spawn', (Spawn, test, it) -> 

    EVENTS   = {}
    NOTIFIER = event: bad: (title, payload) -> EVENTS[title] = payload

    it 'spawns a child process with the coffee interpreter', (done) -> 
        
        Spawn NOTIFIER,

            arguments: ['res/test.coffee']

            (error, child) -> 

                child.stdout.on 'data', (data) -> 

                    if data.toString().match(/OK/)? 

                        test done


    it 'inherits parents env', (done) -> 

        process.env['VARIABLE'] = 'VALUE'

        Spawn NOTIFIER,

            arguments: ['res/test.coffee']

            (error, child) -> 

                child.stdout.on 'data', (data) -> 

                    if data.toString().match(/VALUE/)?

                         test done


    it 'notifies on exit', (done) -> 

        Spawn NOTIFIER,

            arguments: ['res/test.coffee']        

            (error, child) -> 

                setTimeout (->

                    EVENTS['child exited'].should.eql 

                        code: 255
                        signal: ''

                    test done

                ), 1000


    it 'calls opts.exit() with pid on exit', (done) -> 

        PID = undefined

        Spawn NOTIFIER,

            arguments: ['res/test.coffee']

            exit: (pid) -> 

                pid.should.equal PID
                test done

            (error, child) -> 

                PID = child.pid

                