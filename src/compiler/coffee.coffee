fs         = require 'fs'
path       = require 'path'
wrench     = require 'wrench'
coffee     = require 'coffee-script'
colors     = require 'colors'
inflection = require 'inflection'

module.exports = compiler = 

    compile: (logger, config, callback) -> 

        inFile  = config.file
        outFile = config.file.replace config.src, ''
        outPath = config.dst + outFile

        try

            source = fs.readFileSync( inFile ).toString()

            js = coffee.compile source, 

                bare: true
                header: true

            wrench.mkdirSyncRecursive path.dirname( outPath ), '0755'

            file = outPath.replace /\.coffee$/, '.js'

            fs.writeFileSync file, js

            callback null

        catch error

            if error.toString().match /SyntaxError/

                compiler.showError config.src, outFile, source, error

            callback error

    ensureSpec: (logger, config, callback) -> 

        create   = false
        outFile  = config.file.replace config.src, ''
        specFile = outFile.replace /\.coffee$/, '_spec.coffee'
        file     = config.spec + specFile

        try 
            fs.lstatSync file

            #
            # a file already exists at spec path
            #

            callback null, false
            return

        try


            #
            # TODO: allow configable default spec snippet 
            #

            basename  = path.basename(config.file).replace /\.coffee$/, ''
            classname = inflection.camelize basename

            wrench.mkdirSyncRecursive path.dirname( file ), '0755'
            fs.writeFileSync file, """
            require('nez').realize '#{classname}', (context, test, #{classname}) -> 

                context 'in CONTEXT', (it) ->

                    it 'does an EXPECTATION', (done) ->

                        test done


            """

            callback null, true
            return

        catch error

            callback error, false
            return

       
        


    showError: (path, file, source, error) -> 

        first_line = error.location.first_line
        last_line = error.location.last_line

        lines = source.split '\n'

        start = first_line - 5
        start = 0 if start < 0
        end = last_line + 5
        end = lines.length - 1 if end > lines.length - 1

        
        
        console.log '\nFile:', path + file.bold
        console.log 'SyntaxError:', error.message.bold.red, '\n'
        for num in [start..end]

            line = "#{num}  #{lines[num]}"

            if num >= first_line and num <= last_line
            
                console.log line.red

            else

                console.log line

        console.log '\n'
