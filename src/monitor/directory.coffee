hound = require 'hound'

module.exports = (path, callback) -> 

    try

        hound.watch(path).on 'change', (file, stats) -> 

            callback null, file, stats

    catch error

        callback error
