{fn} = require '../parser/js'

module.exports = 

    #
    # leaf detection (for leafOnly: true)
    # -----------------------------------
    # 
    # * Defaults to matching for a phrase whose first argument is a function 
    #   that is called without arguments by the phrase function, or by a 
    #   function nested within.
    # 
    #   ie.
    # 
    #   it 'is not a leaf', (because) ->        
    #  
    #       because 'because is called with arguments', (but) -> 
    #  
    #           but 'this is a leaf', (done) ->
    # 
    #               done() # has no arguments
    #   
    # * Setting context.isLeaf (function) will override. It receives the
    #   the phrase function definition as arg1.fn and should callback if 
    #   the phrase is a leaf.
    # 
    # * It MUST callback only once.
    # 
    # 

    default: (params, isLeaf) -> 

        return isLeaf false unless params.phrase?  

        #
        # The parser recurses into the function (and all nested functions)
        # 
        # It emits the closure event, with the heap, whenever it encounters 
        # a function with no further functions nested within. 
        # 
        # This means that the closure event could fire with a heap that 
        # indicates the presence of a call to arg1 multiple times. 
        # 
        # Known is set true upon identifying a leaf, to prevent the callback 
        # to isLeaf being repeated on the same leaf detection run.
        #

        parser = fn.parser()
        known  = false
        

        parser.on 'closure', (heap) -> 

            return if known

            #
            # doneSig is the first argument >>name<< on the root 
            # function of the phrase.
            # 
            # ie.  stacker 'phrase text', (foo, more, things) -> 
            #      
            #      Will need to find an instance of a call to
            #      foo() without arguments to determine the
            #      leaffyness of the phrase.
            # 

            rootFn  = heap[0]
            doneSig = rootFn.signature[0]
            matcher = new RegExp "#{doneSig}\\(\\)"

            #
            # loop into the closure heap in search of 
            # argless call to doneSig, 
            # 

            depth         = 0
            declaredDepth = 0

            for closure in heap

                depth++

                unless closure.signature.indexOf(doneSig) < 0 

                    #
                    # this function has doneSig passed in, if it is 
                    # not the root function of the phrase then any 
                    # call to doneSig at this or greater depth is 
                    # not eligable for leafhood considderation
                    # 

                    declaredDepth = depth

                for statement in closure.statements

                    if match = statement.match matcher

                        #
                        # doneSig() has been called in statement
                        #

                        if declaredDepth == 1

                            #
                            # doneSig still refers onto the 
                            # root function's scope
                            # 

                            known = true
                            isLeaf true


        parser.on 'end', -> 

            return if known
            isLeaf false


        parser.parse params.fn.toString()

