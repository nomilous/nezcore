require('nez').realize 'Core', (Core, test, it) -> 
    
    for toolset in ['config', 'injector']

        it "exports #{toolset}", (done) ->

            Core[toolset].should.equal require "../lib/#{toolset}/#{toolset}"
            test done
