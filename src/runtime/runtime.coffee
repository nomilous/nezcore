commander = require 'commander'
Logger    = require '../logger/logger'
Monitors  = require '../monitor/monitors'
Compilers = require '../compiler/compilers'

commander.option '-s, --silent',                 'suppresses console output'
commander.option '-v, --verbose',                'amplify console output'
commander.option '    --log-level [level]',      'set console log level (defualt: info)'
commander.option '    --log-file [file]',        'log to file'
commander.option '    --log-file-level [level]', 'set file log level (defualt: info)'

commander.option '\nDownlink Config\n', ''

commander.option '   --adaptor [adaptor]',      'listen with adaptor (default socket.io)'
commander.option '   --iface [iface]',          'listen on iface (default 127.0.01)'
commander.option '   --port [port]',            'listen on port (default any)'


commander.option '\nUplink Config\n', ''

commander.option '   --uplink-adaptor [adaptor]',   'connect with adaptor (default socket.io)'
commander.option '   --uplink-uri [uri]',           'connect to uri (http://localhost:10101)'


class Runtime

    constructor: ->

        commander.parse process.argv

        #
        # runtime provides a logger
        #

        @loadLogger commander

        #
        # runtime provides monitors
        #

        @loadMonitors commander

        #
        # runtime provides compilers
        # 

        @loadCompilers commander


        @loadListen()
        @loadConnect()

        @logger.verbose => 'starting runtime' 
        @logger.verbose => 'pending listen': parameters: @listen
        @logger.verbose => 'pending connect': parameters: @connect

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

    loadConnect: -> 

        @connect = 

            #
            # **runtime.connect**
            # 
            # Parameters to configures the scaffold to connect 
            # to remote super-objectives.
            # 

            adaptor: commander.uplinkAdaptor || process.env.UPLINK_ADAPTOR || 'socket.io'
            uri: commander.uplinkUri         || process.env.UPLINK_URI     || 'http://localhost:10101'

    loadLogger: (commander) -> 

        opts = {}

        level = commander.logLevel || process.env.LOG_LEVEL || 'info'

        unless commander.silent and not commander.verbose

            consoleLevel = level
            consoleLevel = 'verbose' if commander.verbose

            opts.console = 

                level: consoleLevel
                colorize: true

        if commander.logFile

            level = commander.logFileLevel if commander.logFileLevel

            opts.file = 

                level: level
                filename: commander.logFile

        @logger = new Logger opts

    loadMonitors: (commander) -> 

        @monitors = Monitors


    loadCompilers: (commander) -> 

        @compilers = Compilers


module.exports = Runtime
