hound = require 'hound'

module.exports = 

    watch: (path, callback) -> 

        try

            hound.watch path

        catch error

            callback error
