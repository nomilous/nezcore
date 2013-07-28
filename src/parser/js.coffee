{EventEmitter} = require 'events'

#
# resurse into a function definition and emit the 'closure heap' 
# at every leaf node
#

exports.fn = 

    parser: -> 

        emitter       = new EventEmitter
        stack         = []
        emitter.parse = recurse = (jsString) -> 

            if match = jsString.match /function\s*\((.*)\)\s*{/    

                fn =

                    #
                    # arg signature of the function
                    #

                    signature: match[1].replace(/[\s]/g, '' ).split ','

                    #
                    # variables declared in the function
                    #

                    variables: []

                    # 
                    # array of statements on the function root
                    # 

                    statements: []

                    #
                    # body of the function
                    #

                    body: ''

                #
                # step into the remaining text that follows the match
                # char by char looking for the end of the function by
                # counting curlies
                # 

                remaining  = jsString.substring match.index + match[0].length
                curlyDepth = 0
                statement  = ''

                for char in remaining

                    if char == '{' then curlyDepth++
                    else if char == '}' then curlyDepth--

                    if curlyDepth >= 0 

                        #
                        # accumulate function body
                        #

                        fn.body += char


                    if curlyDepth == 0

                        #
                        # on the root of the function
                        #

                        if char == ';'

                            #
                            # store and reset accumulated statement 
                            #

                            statement = statement.replace /^[\s]+/g, ''
                            statement = statement.replace /[\s]+$/g, ''


                            if vars = statement.match /^var\s(.*)/

                                vars[1].split(',').map (variable) -> 

                                    fn.variables.push variable.replace /^[\s]+/g, ''

                            else 

                                fn.statements.push statement
                            
                            statement = ''

                        else

                            #
                            # accumulate statement
                            #

                            statement += char unless char == '}'


                    if curlyDepth < 0 

                        # 
                        # remove leading and trailing whitespace
                        #

                        fn.body = fn.body.replace /^[\s]+/g, ''
                        fn.body = fn.body.replace /[\s]+$/g, ''
                        break

                if fn.signature[0] == '' then fn.signature = []

                stack.push fn

                if fn.body.match /function\s*\(/

                    #
                    # function body has a nested function, recurse
                    #

                    recurse fn.body

                else      

                    #
                    # no further nested functions, 
                    # emit >>>deepcopy<<< of stack
                    #

                    emitter.emit 'closure', JSON.parse JSON.stringify stack

                stack.pop()


                #
                # recurse on the all remaining text that follows the function
                #

                remaining = remaining.substring fn.body.length
                recurse remaining

                #
                # end on stackdepth 0
                #

                # if stack.length == 0 then emitter.emit 'end' 

            else 

                if stack.length == 0 then emitter.emit 'end' 


        return emitter