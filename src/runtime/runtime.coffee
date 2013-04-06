commander = require 'commander'
winston   = require 'winston'

commander.option '-s, --silent',                 'suppresses console output'
commander.option '-v, --verbose',                'amplify console output'
commander.option '    --log-level [level]',      'set console log level (defualt: info)'
commander.option '    --log-file [file]',        'log to file'
commander.option '    --log-file-level [level]', 'set file log level (defualt: info)'

commander.option '\nDownlink Config', ''
commander.option 'To listen for remote realizers or sub-objectives.\n', ''

commander.option '   --adaptor [adaptor]',      'listen with adaptor (default socket.io)'
commander.option '   --iface [iface]',          'listen on iface (default 127.0.01)'
commander.option '   --port [port]',            'listen on port (default any)'


commander.option '\nUplink Config', ''
commander.option 'Attach to super-objective\n', ''

commander.option '   --uplink-adaptor [adaptor]',   'connect with adaptor (default socket.io)'
commander.option '   --uplink-uri [uri]',           'connect to uri (http://localhost:10101)'


class Runtime

    constructor: ->

        commander.parse process.argv

        @loadLogger()
        @loadListen()

        @logger.verbose 'starting runtime' 
        @logger.verbose 'pending listen', @listen
        @logger.verbose 'pending connect', @connect

    loadListen: -> 

        @listen = 

            #
            # **runtime.listen**  
            # 
            # Parameters to configures the scaffold to listen 
            # for remote realizers / sub-objectives.
            # 

            adaptor: commander.adaptor || process.env.LISTEN_ADAPTOR || 'socket.io'
            iface:   commander.iface   || process.env.LISTEN_IFACE   || '127.0.0.1'
            port:    commander.port    || process.env.LISTEN_PORT    || null


        @connect = 

            #
            # **runtime.connect**  
            # 
            # Parameters to configures the scaffold to connect 
            # to remote super-objectives.
            # 

            adaptor: commander.uplinkAdaptor || process.env.UPLINK_ADAPTOR || 'socket.io'
            uri: commander.uplinkUri         || process.env.UPLINK_URI     || 'http://localhost:10101'



    loadLogger: -> 

        logFileLevel = commander.logFileLevel || process.env.LOG_LEVEL || 'info'
        logFile      = commander.logFile      || process.env.LOG_FILE

        logLevel     = commander.logLevel     || process.env.LOG_LEVEL || 'info'
        logLevel     = 'verbose' if commander.verbose

        transports = []

        unless commander.silent and not commander.verbose

            transports.push new winston.transports.Console 

                    level: logLevel
                    colorize: true

        if commander.logFile

            transports.push new winston.transports.File

                    filename: commander.logFile
                    level: logFileLevel

        @logger = new winston.Logger
  
            transports: transports


module.exports = Runtime
