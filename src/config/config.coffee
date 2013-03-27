fs     = require 'fs'
config = null

# 
# private config class 
# 

class Config

    @fromFile: (opts) -> 

        try

            content = fs.readFileSync opts.file

        catch error

            console.log 'error loading config from file:', opts.file
            process.exit 100

#
# public config interface
#

module.exports = 

    load: (opts) -> 

        if opts.file

            config = Config.fromFile opts
            return 
