fs     = require 'fs'
crypto = require 'crypto'

module.exports = 

    file: (filename) -> 

        md5sum = crypto.createHash 'md5'
        md5sum.update fs.readFileSync( filename ).toString()
        md5sum.digest 'hex'