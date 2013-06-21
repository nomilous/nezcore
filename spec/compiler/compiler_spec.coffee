require('nez').realize 'Compiler', (Compiler, test, it) -> 

    it 'exports coffee compiler', (done) ->

        Compiler.coffee.should.equal require '../../lib/compiler/coffee'
        test done
