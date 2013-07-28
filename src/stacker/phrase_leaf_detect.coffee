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

        unless params.phrase? 

            return isLeaf false

        isLeaf true
