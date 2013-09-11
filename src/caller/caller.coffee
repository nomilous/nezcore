{EOL} = require 'os'

exports.filename = -> 

    for line in Error.apply( this ).stack.split EOL

        continue unless match = line.match /at\s(.*)\s\((.*?):/
        call = match[1]
        filename = match[2]
        if next++ == 2 then return filename
        next = 0 if call == 'Object.exports.filename' and filename.match /nezcore.*caller.js$/
