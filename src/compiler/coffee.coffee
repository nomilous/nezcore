fs         = require 'fs'
path       = require 'path'
wrench     = require 'wrench'
coffee     = require 'coffee-script'
colors     = require 'colors'
inflection = require 'inflection'
uuid       = require 'node-uuid'

module.exports = compiler = 

    compile: (notice, config, callback) -> 

        inFile  = config.file
        outFile = config.file.replace config.src, ''
        outPath = config.dst + outFile

        try

            source = fs.readFileSync( inFile ).toString()

            js = coffee.compile source, 

                bare: true
                header: true
                literate: outFile.match(/litcoffee/)?

            unless config.dst? 

                return callback null, js

            wrench.mkdirSyncRecursive path.dirname( outPath ), '0755'

            file = outPath.replace /\.(lit)*coffee$/, '.js'

            fs.writeFileSync file, js

            return callback null

        catch error

            if error.toString().match /SyntaxError/

                compiler.showError config.src, outFile, source, error

            callback error

    ensureSpec: (notice, config, callback) -> 

        create   = false
        outFile  = config.file.replace config.src, ''

        

        if outFile.match /_spec\.coffee$/

            file = config.spec + outFile

        else

            specFile = outFile.replace /\.(lit)*coffee$/, '_spec.coffee'
            file     = config.spec + specFile

        try 

            fs.lstatSync file

            #
            # a file already exists at specpath
            #

            try

                buff = fs.readFileSync file
                content = buff.toString()

                unless content.match /###\s*UUID/

                    #
                    # Attach unique identider to spec if not present
                    #

                    content = "### UUID #{uuid.v1()} ###\n\n" + content
                    fs.writeFileSync file, content

            callback null, file
            return

        catch error

            callback error unless error.code == 'ENOENT'

        try


            #
            # TODO: allow configable default spec snippet 
            #

            basename  = path.basename(config.file).replace /\.(lit)*coffee$/, ''
            classname = inflection.camelize basename

            wrench.mkdirSyncRecursive path.dirname( file ), '0755'
            fs.writeFileSync file, """
            ### UUID #{uuid.v1()} ###

            require('nez').realize '#{classname}', (context, test, #{classname}) -> 

                context 'context', (it) ->

                    it 'does something', (done) ->

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
