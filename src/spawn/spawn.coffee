spawn = require('child_process').spawn
path  = require 'path'

module.exports = (notice, opts, callback) -> 

    #
    # start script on the local coffee interpreter 
    #

    command = path.normalize __dirname + '/../../node_modules/.bin/coffee'
    child   = spawn command, opts.arguments


    #
    # terminating child notifies (event.bad)
    #

    child.on 'exit', (code, signal) -> 

        if typeof opts.exit == 'function'

            opts.exit child.pid, code, signal 

        if code != 0 

            return notice.event.bad 'child exited'

                opts:   opts
                pid:    child.pid
                code:   code
                signal: signal || ''


        notice.event 'child exited'

            opts:   opts
            pid:    child.pid
            code:   code
            signal: signal || ''

    
    #
    # todo: vanishing output from script could become important
    # 
    #       hmmmmm? > 
    #

    child.stderr.on 'data', (data) -> 
    child.stdout.on 'data', (data) -> 

    callback null, child
