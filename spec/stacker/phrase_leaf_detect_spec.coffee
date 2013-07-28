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


        context 'is not a leaf if phrase is defined and', -> 

            it 'and the call to done refers to an arg passed into the nested scope'

            it 'and the call to done refers to an variable declared in the nested scope'



