{inject, util}    = require 'also' 
PhraseLeafDetect = require './phrase_leaf_detect'
PhraseInjector   = require './phrase_injector'

#
# PhraseStack
# ===========
# 
# 
# 
#     stacker = PhraseStack.create CONFIG, NOTIFIER, (phrase) -> 
# 
# 
#     phrase 'phrase text', (nested) -> 
# 
#         console.log nested.stack
#     
#         nested 'nested phrase text', (done) -> 
# 
#             console.log done.stack
#
# 

module.exports = 

    create: (context, notice, rootFn) -> 

        stack   = []

        context.isLeaf ||= PhraseLeafDetect.default

        phraseStacker = (elementName, control) -> 



            injectionContext = 

                elementName: elementName
                context:     context
                stack:       stack


            injectionControl = 

                parallel:    false
                timeout:     control.timeout || 0
                beforeAll:   PhraseInjector.beforeAll  injectionContext, control
                beforeEach:  PhraseInjector.beforeEach injectionContext, control
                afterEach:   PhraseInjector.afterEach  injectionContext, control
                afterAll:    PhraseInjector.afterAll   injectionContext, control
                onError:     (error) -> console.log error.stack
                onTimeout:   PhraseInjector.onTimeout  injectionContext, control


            #
            # create injection function 
            # 

            injectionFunction = inject.async injectionControl, (phrase, nestedControl, fn) -> 

                    #
                    # recurse phraseStacker into arg1 of fn
                    #

                    childElementName = util.argsOf( fn )[0]
                    fn phraseStacker childElementName, nestedControl




            Object.defineProperty injectionFunction, 'stack', 

                get: -> stack
                enumerable: false

            Object.defineProperty injectionFunction, 'top', 

                get: -> stack[stack.length - 1]
                enumerable: false



            return injectionFunction


        #
        # PhraseStacker.create() returns root injectionFunction 
        # -----------------------------------------------------
        # 
        # * element named from arg1 of the rootFn
        # * control from the master context
        # 

        return phraseStacker util.argsOf( rootFn )[0], context




#
# TODO
# ----
# 
# * shutdown async timeout (it's additive, cant do 2 seconds per phrase 
#   because parent also only gets 2)
# 
# * implement local timeout as optional (activated if done in signature)
# 
# * allow per phrase specifying of timeout for nested tree
#        
# * separate timeout for hooks (same to apply per activation and config)
# 
# * inject modules / local classes per signature of args [1..] 
#   of each phrase function
# 
# * allow specifying module / class for cases of inline unfriendly names
# 
#   ie   phrase 'phrase text', (nested, should, MyClass) -> 
#        
#             should.should.equal  require 'should'
#             MyClass.should.equal require '../../{searched}/lib/my_class'
# 
#                                                                   #
#                                                                   # illegal js
#                                                                   # 
#             nested 'cannot inject names with - and .', (done, some-thing) -> 
# 
#                 done()
# 
# * consider using coffee-script feature-thingy-majig (if still in the latest version
#                                               and behaves itself)
# 
#   ie    phrase 'phrase text', (nested, module:ClassName) -> 
#  
#              c = new ClassName()
#  

