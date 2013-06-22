hound = require 'hound'

module.exports = (notice, path, callback) -> 

    try

        hound.watch(path).on 'change', (file, stats) -> 

            callback 'change', file, stats

    catch error

        callback error
