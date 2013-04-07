require('nez').realize 'Coffee', (Coffee, test, it, should) -> 

    it 'compiles coffee-script', (done, fs) ->

        fs.readFileSync = -> 

            console.log arguments

            return """ 

                require 'milk'
                require 'sugar'
                require mug'
                require 'teaspoon'
                require 'kettle'

            """

        Coffee.compile {}, 'FILE', (error) -> 

            should.exist error
            test done
