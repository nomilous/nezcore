# eligable? DELETE

fs     = require 'fs'

# 
# private config class 
# 

class Config

    constructor: (opts) -> 

        for key of opts

            @[key] = opts[key]

    fromFile: (fileName) -> 

        try

            content = fs.readFileSync fileName

        catch error

            console.log 'error loading config from file:', fileName
            process.exit 100


#
# defaults
#

if typeof runningConfig == 'undefined'

    runningConfig = new Config 

        #
        # pending person module
        #

        secret: 'SEEKRIT'
        adaptor: 'socket.io'
        home: 'http://localhost:10101'


        


#
# public config interface
#

module.exports = 

    load: (opts) -> 

        if opts.file

            runningConfig.fromFile opts.file
            return

    get: (key) -> runningConfig[key]

    hup: -> 

        #
        # TODO: changed?
        #

        # pendingConfig = new Config
        # runningConfig = new Config




