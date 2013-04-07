fs     = require 'fs'
coffee = require 'coffee-script'
colors = require 'colors'

module.exports = compiler = 

    compile: (logger, file, callback) -> 

        try

            source = fs.readFileSync(file).toString()

            js = coffee.compile source, bare: true

            console.log 'TODO: write compiled file'

            callback null

        catch error

            if error.toString().match /SyntaxError/

                compiler.showError file, source, error

            callback error


    showError: (file, source, error) -> 

        first_line = error.location.first_line
        last_line = error.location.last_line

        lines = source.split '\n'

        start = first_line - 5
        start = 0 if start < 0
        end = last_line + 5
        end = lines.length - 1 if end > lines.length - 1

        
        
        console.log '\nFile:', file
        console.log 'SyntaxError:', error.message.bold.red, '\n'
        for num in [start..end]

            line = "#{num}  #{lines[num]}"

            if num >= first_line and num <= last_line
            
                console.log line.red

            else

                console.log line

        console.log '\n'
