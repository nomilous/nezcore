spawn = require('child_process').spawn
path  = require 'path'

module.exports = (opts, callback) -> 

    #
    # start script on the local coffee interpreter 
    #

    command = path.normalize __dirname + '/../../node_modules/.bin/coffee'
    callback null, spawn command, opts.arguments
