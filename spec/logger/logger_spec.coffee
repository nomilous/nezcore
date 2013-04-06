require('nez').realize 'Logger', (Logger, test, context, should, winston) -> 

    original = winston.Logger

    context 'config', (it) -> 

        it 'loads no log transports by default', (done) ->

            winston.Logger = class MockLogger

                constructor: (opts) -> 

                    opts.should.eql 
                        transports: []

                    test done

            new Logger 

        it 'can load a file logger', (done) ->

            winston.Logger = class MockLogger

                constructor: (opts) -> 

                    transport = opts.transports[0]
                    transport.should.be.an.instanceof winston.transports.File
                    transport.level.should.equal 'info'
                    test done

            new Logger 
                file: 
                    filename: 'm'
                    level: 'info'

        it 'can load a console logger', (done) ->

            winston.Logger = class MockLogger

                constructor: (opts) -> 

                    transport = opts.transports[0]
                    transport.should.be.an.instanceof winston.transports.Console
                    transport.level.should.equal 'verbose'
                    test done

            new Logger 
                console: 
                    level: 'verbose'

        it 'can load file and console logger', (done) -> 

            winston.Logger = class MockLogger

                constructor: (opts) -> 

                    transports = opts.transports
                    transports.length.should.equal 2
                    test done

            new Logger
                console: 
                    level: 'info'
                file:
                    level: 'info'
                    filename: 'm'

    context 'levels', (it) -> 

        winston.Logger = original

        for level in ['silly','verbose','info','warn','debug','error']

            it "implements call for '#{level}'", (done) -> 

                (new Logger)[level].should.be.an.instanceof Function
                test done
  
        it 'knows which log levels are active', (done) -> 

            winston.Logger = class MockLogger

                constructor: (opts) -> 

            logger = new Logger
                    console: 
                        level: 'error'
                    file: 
                        level: 'info'
                        filename: 'm'

            logger.levels.should.eql 

                silly: false
                verbose: false
                info: true
                warn: true
                debug: true
                error: true

            test done
            

    context 'logs functionally', (it) -> 

        winston.Logger = original

        logger = new Logger console: level: 'info'

        it 'passes a function that returns the log message', (done) ->

            logger.logger.info = (message, meta) -> 

                message.should.equal 'log message'
                meta.should.eql meta: 'data'
                test done

            logger.info -> 'log message': 

                meta: 'data'


        it 'does not call the function if the corresponding level is not active', (done) -> 

            called = false
            logger.logger.verbose = (message, meta) -> called = true

            logger.verbose -> thing: 'stuff'
            called.should.equal false
            test done


    context 'log() function', (it) -> 

        winston.Logger = original

        logger = new Logger console: level: 'verbose'

        it 'processes more than one log level message', (done) -> 

            calledInfo = false
            calledVerbose = false

            logger.logger.info = (message, meta) -> 
                message.should.equal 'an info level message'
                calledInfo = true

            logger.logger.verbose = (message, meta) -> 
                message.should.equal 'a verbose level message'
                meta.should.eql meta: 'data'
                calledVerbose = true


            logger.log 

                info: -> 'an info level message'

                verbose: -> 'a verbose level message': 

                    meta: 'data'


            calledInfo.should.equal true
            calledVerbose.should.equal true
            test done

    context 'compatability', (it) -> 

        winston.Logger = original

        logger = new Logger console: level: 'verbose'

        it 'supports standard log()', (done) -> 

            logger.logger.log = (level, message, meta) -> 
                level.should.equal 'info'
                message.should.equal 'message'
                meta.should.eql meta: 'data'
                test done

            logger.log 'info', 'message', meta: 'data'

        it 'supports standard info()', (done) -> 

            logger.logger.info = (message, meta) -> 
                console.log 'ARGS', arguments
                message.should.equal 'message'
                meta.should.eql meta: 'data'
                test done

            logger.info 'message', meta: 'data'
