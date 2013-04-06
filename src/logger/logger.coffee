winston = require 'winston'
logger  = undefined

module.exports = class Logger

    constructor: (opts = {}) -> 

        @_levels = 

            silly: false
            verbose: false
            info: false
            warn: false
            debug: false
            error: true

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

        @logger = new winston.Logger
  
            transports: transports


    silly:   (message) -> @logger.silly.apply null, @process message()
    verbose: (message) -> @logger.verbose.apply null, @process message()
    info:    (message) -> @logger.info.apply null, @process message()
    warn:    (message) -> @logger.warn.apply null, @process message()
    debug:   (message) -> @logger.debug.apply null, @process message()
    error:   (message) -> @logger.error.apply null, @process message()
        
    process: (message) -> 

        if typeof message == 'string'

            return [message]

        else if message instanceof Object

            for key of message

                return [key, message]

    loadLevels: (level) -> 

        active = false

        for _level of @_levels

            active = true if level == _level

            @_levels[_level] = active


