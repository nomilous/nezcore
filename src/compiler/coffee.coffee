fs         = require 'fs'
path       = require 'path'
wrench     = require 'wrench'
coffee     = require 'coffee-script'
colors     = require 'colors'
inflection = require 'inflection'

module.exports = compiler = 

    compile: (config, callback) -> 

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

    ensureSpec: (config, callback) -> 

        create   = false
        outFile  = config.file.replace config.src, ''
        specFile = outFile.replace /\.coffee$/, '_spec.coffee'
        file     = config.spec + specFile

        try 
            fs.lstatSync file

            #
            # a file already exists at specpath
            #

            callback null, file
            return

        catch error

            throw error unless error.code == 'ENOENT'

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

            #
            # created spec file, hound will see it
            # so no need to pass the specFile to callback 
            #

            callback null
            return

        catch error

            callback error
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
