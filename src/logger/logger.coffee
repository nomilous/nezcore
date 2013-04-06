winston = require 'winston'
logger  = undefined
levels  = 
    silly: false
    verbose: false
    info: false
    warn: false
    debug: false
    error: true

module.exports = class Logger

    constructor: (opts = {}) -> 

        @levels = levels   

        transports = []

        unless typeof opts.console == 'undefined'

            @loadLevels opts.console.level

            transports.push new winston.transports.Console

                level: opts.console.level
                colorize: opts.console.colorize

        unless typeof opts.file == 'undefined'

            @loadLevels opts.file.level

            transports.push new winston.transports.File

                    filename: opts.file.filename
                    level: opts.file.level

        logger = @logger = new winston.Logger
  
            transports: transports


    silly: -> 

        return unless levels.silly
        logger.silly.apply null, @process arguments


    verbose: -> 

        return unless levels.verbose
        logger.verbose.apply null, @process arguments


    info: -> 

        return unless levels.info
        logger.info.apply null, @process arguments


    warn: -> 

        return unless levels.warn
        logger.warn.apply null, @process arguments


    debug: -> 

        return unless levels.debug
        logger.debug.apply null, @process arguments


    error: -> 

        return unless levels.error
        logger.error.apply null, @process arguments

    log: (messages) -> 

        if typeof messages == 'string'

            return logger.log.apply null, arguments

        for level of messages
            continue unless levels[level]
            @[level] messages[level]

        
    process: (args) -> 

        if typeof args[0] == 'string'

            return [args[0], args[1]]

        message = args[0]()

        if typeof message == 'string'

            return [message]

        else if message instanceof Array

            return message

        else

            for key of message

                return [key, message[key]]


    loadLevels: (level) -> 

        active = false

        for _level of @levels

            active = true if level == _level

            @levels[_level] = active


