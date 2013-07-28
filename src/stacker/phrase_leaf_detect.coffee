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

            #
            # loop into the closure heap for in search of 
            # argless call to doneSig
            #
            depth = 0
            for closure in heap

                depth++
                for statement in closure.statements

                    if match = statement.match new RegExp "#{doneSig}\\(\\)"

                        #
                        # doneSig() has been called in statement
                        #

                        if depth == 1

                            #
                            # called as statement in the rootFn, 
                            # definately a leaf
                            # 

                            known = true
                            isLeaf true

                        else

                            #
                            # called as statement in nested function
                            # is only a leaf if:
                            # ------------------
                            # 
                            # * done is not a local variable declared
                            #   or passed into this nested function
                            # 
                            # * done is not a variable scoped to the
                            #   parent function, but the parent is 
                            #   also not the root 
                            # 

                            console.log todo: 'The Scope of DoneSig' 

                            known = true
                            isLeaf true


        parser.on 'end', -> 

            return if known
            isLeaf false


        parser.parse params.fn.toString()

