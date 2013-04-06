winston = require 'winston'

module.exports = class Logger

    constructor: (opts = {}) -> 

        transports = []

        unless typeof opts.console == 'undefined'

            transports.push new winston.transports.Console

                level: opts.console.level
                colorize: opts.console.colorize

        unless typeof opts.file == 'undefined'

            transports.push new winston.transports.File

                    filename: opts.file.filename
                    level: opts.file.level

        @logger = new winston.Logger
  
            transports: transports

        return @logger
