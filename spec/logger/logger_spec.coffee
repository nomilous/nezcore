require('nez').realize 'Logger', (Logger, test, context, should) -> 

    context 'config', (it, winston) -> 

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

        
