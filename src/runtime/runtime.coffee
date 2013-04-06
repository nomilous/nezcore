commander = require 'commander'
winston   = require 'winston'

commander.option '-s, --silent',                 'suppresses console output'
commander.option '-v, --verbose',                'amplify console output'
commander.option '    --log-level [level]',      'set console log level (defualt: info)'
commander.option '    --log-file [file]',        'log to file'
commander.option '    --log-file-level [level]', 'set file log level (defualt: info)'


class Runtime

    constructor: ->

        commander.parse process.argv

        @setLogger()

        @logger.verbose 'starting runtime'


    setLogger: -> 

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
