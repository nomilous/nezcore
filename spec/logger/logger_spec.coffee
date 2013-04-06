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

            logger._levels.should.eql 

                silly: false
                verbose: false
                info: true
                warn: true
                debug: true
                error: true

            test done
            

    context 'logs functionally', (done) -> 

        winston.Logger = original

        logger = new Logger console: level: 'info'

        logger.logger.info = (message, meta) -> 

            message.should.equal 'thing'
            meta.should.eql thing: 'stuff'
            test done

        logger.info -> thing: 'stuff'

