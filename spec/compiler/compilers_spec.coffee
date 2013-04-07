require('nez').realize 'Compilers', (Compilers, test, it) -> 

    it 'exports coffee compiler', (done) ->

        Compilers.coffee.should.equal require '../../lib/compiler/coffee'
        test done
