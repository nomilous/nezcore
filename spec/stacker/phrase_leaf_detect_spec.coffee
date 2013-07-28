PhraseStack      = require '../../lib/stacker/phrase_stack'
PhraseLeafDetect = require '../../lib/stacker/phrase_leaf_detect'
should           = require 'should'

describe 'PhraseLeafDetect', -> 

    context 'default detection', -> 

        it 'is not a leaf if phrase is undefined', (done) -> 

            PhraseLeafDetect.default 

                fn: (done) -> done()
                (leaf) -> 

                    leaf.should.equal false
                    done()


        context 'is a leaf if phrase is defined and', ->

            it 'calls done in the phrase fn ', (done) -> 

                PhraseLeafDetect.default

                    phrase: 'phrase'
                    fn: (done) -> done()

                    (leaf) -> 

                        leaf.should.equal true
                        done()


            it 'calls done in a nested function of the phrase fn', (done) -> 

                PhraseLeafDetect.default

                    phrase: 'phrase'
                    fn: (done) -> nested = -> done()

                    (leaf) -> 

                        leaf.should.equal true
                        done()


            it 'calls done by some other name', (done) -> 

                PhraseLeafDetect.default

                    phrase: 'phrase'
                    fn: (goal) -> nested = -> goal()

                    (leaf) -> 

                        leaf.should.equal true
                        done()


        context 'is not a leaf if phrase is defined and', -> 

            it 'the call to done refers to an arg passed into the nested scope', (done) -> 

                PhraseLeafDetect.default

                    phrase: 'phrase'

                    fn: (done) -> 

                        nested = (done) -> 

                            #
                            # not a leaf - done is called, but does not
                            # refer to the instance of done as passed 
                            # into the root function in the phrase
                            #

                            done()

                    (leaf) -> 

                        leaf.should.equal false
                        done()


            it 'the call is nested even deeper and still refers to the worng done', (done) ->

                 PhraseLeafDetect.default

                    phrase: 'phrase'

                    fn: (done) -> 

                        nested = (done) -> 

                            setTimeout (-> 

                                #
                                # still not a leaf, done does not refer
                                # to the instance on the root fn
                                #

                                done()

                            ), 100

                    (leaf) -> 

                        leaf.should.equal false
                        done()


            it 'the call to done refers to a variable declared in the nested scope'



