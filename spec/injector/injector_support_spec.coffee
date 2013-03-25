require('nez').realize 'InjectorSupport', (InjectorSupport, test, context, should, Injector) -> 

    context 'findModule()', (context) -> 

        context 'when called from a spec run', (it) -> 

            it 'finds the repo root by matching for /spec/', (done) -> 

                #
                # mock support.getModule
                #

                InjectorSupport.getModulePath = (name, root, search) ->

                    name.should.equal 'name_of_module'
                    root.should.match /node_modules\/nezcore$/
                    search.should.eql ['lib', 'app', 'bin']

                    #
                    # return a findable module path
                    #

                    return '../../lib/injector/injector'


                InjectorSupport.findModule(

                    { module: 'NameOfModule' }

                ).should.equal Injector


    context 'fn2modules()', (it) -> 

        it 'converts function arguments to module definitions', (done) ->

            InjectorSupport.fn2modules( 

                (humpty, dumpty) -> 

            ).should.eql [
            
                { module: 'humpty' }
                { module: 'dumpty' }

            ]

            test done


        it 'supports : delimited hierarchy for foussed injection', (With) -> 

            # 
            # console.log '\n%s\n', require('coffee-script').compile '(one, two:a, three:b)->'
            # 
            # (function() {
            # 
            #   (function(one, _arg) {
            #     var a, b;
            #     a = _arg.two, b = _arg.three;
            #   });
            # 
            # }).call(this);
            # 


            With 'a test that fails if future coffee-script compiler output changes', (done) -> 

                require('coffee-script').compile(

                    '(a, b:c, d:e:f, g) -> '

                ).should.match(

                    /c = _arg\.b, \(_ref = _arg\.d, f = _ref\.e, g = _ref\.g\);/

                )

                require('coffee-script').compile(

                    '(a, b:c, d:e:f, g) -> '

                ).should.match(

                    /function\(a, _arg\)/

                )

                test done


            With 'all having uniform depth', (done) -> 

                InjectorSupport.fn2modules(

                    (mod1:class1, mod2:class2, mod3:class3) -> 

                ).should.eql [{ 

                    _nested: 

                        class1: ['mod1','class1']   # all these need to be injected as
                        class2: ['mod2','class2']   # the single _arg as compiled
                        class3: ['mod3','class3']   #                 
                    
                }]

                test done


            With 'inital "and final as flat"', (done) -> 

                InjectorSupport.fn2modules(

                    (mod0, mod1, mod2:class2, mod3:class3, mod4) -> 

                ).should.eql [
                    {module: 'mod0'}
                    {module: 'mod1'}
                    {
                        _nested: {

                            class2: ['mod2', 'class2']
                            class3: ['mod3', 'class3']
                            mod4:   ['mod4']  

                        }
                    }
                ]

                test done


            # With 'mixed depth and deepest firts', (done) -> 

            #     InjectorSupport.fn2modules(

            #         (mod0, mod1:class1:function1, mod2:class2, mod3:class3, mod4) -> 
            #             '(mod0, mod1:class1:function1, mod2:class2, mod3:class3, mod4)'

            #     ).should.eql [

            #         {module: 'mod0'}
            #         {
            #             _nested: {

            #                 function1: ['mod1','class1','function1']
            #                 class2:    ['mod2', 'class2']
            #                 class3:    ['mod3', 'class3']
            #                 mod4:      ['mod4']  

            #             }
            #         }
            #     ]

            #     test done


            # With 'mixed depth and deepest middle', (done) -> 

                
            #     InjectorSupport.fn2modules(

            #         (mod0, mod2:class2, mod1:class1:function1, mod3:class3, mod4) -> 
            #             '(mod0, mod2:class2, mod1:class1:function1, mod3:class3, mod4)'

            #     ).should.eql [

            #         {module: 'mod0'}
            #         {
            #             _nested: {

            #                 class2:    ['mod2', 'class2']
            #                 function1: ['mod1','class1','function1']
            #                 class3:    ['mod3', 'class3']
            #                 mod4:      ['mod4']  

            #             }
            #         }
            #     ]

            #     test done


            # With 'mixed depth and deepest almost last', (done) -> 

            #     InjectorSupport.fn2modules(

            #         (mod0, mod2:class2, mod1:class1:function1, mod4) -> 

            #     ).should.eql [

            #         {module: 'mod0'}
            #         {
            #             _nested: {

            #                 class2:    ['mod2', 'class2']
            #                 function1: ['mod1','class1','function1']
            #                 mod4:      ['mod4']  

            #             }
            #         }
            #     ]

            #     test done


            # With 'mixed depth and deepest last', (done) -> 

            #     InjectorSupport.fn2modules(

            #         (mod0, mod2:class2, mod4, mod1:class1:function1) -> 

            #     ).should.eql [

            #         {module: 'mod0'}
            #         {
            #             _nested: {

            #                 class2:    ['mod2', 'class2']
            #                 mod4:      ['mod4']  
            #                 function1: ['mod1','class1','function1']
                            

            #             }
            #         }
            #     ]

            #     test done


    context 'loadServices()', (it) -> 

        it 'loads modules dynamically', (done) -> 

            try

                InjectorSupport.loadServices [ module: 'name' ], []

            catch error

                error.should.match /Cannot find module 'name'/
                test done


        it 'loads npm modules dynamically in addition to preDefined modules', (done) -> 

            InjectorSupport.loadServices( 

                [ 
                    {module: 'preDefined1'}
                    {module: 'preDefined2'}
                    {module: 'should'}
                    {module: 'nez'}
                ]
                ['preDefined1', 'preDefined2'] 

            ).should.eql [

                'preDefined1'
                'preDefined2'
                require 'should'
                require 'nez'

            ]

            test done


        it 'loads local modules when CamelCase', (done) -> 

            searchedCount = 0

            #
            # mock findModule
            #

            InjectorSupport.findModule = (config) -> 
                
                return "Fake#{config.module}"
                
            InjectorSupport.loadServices( 

                [ 
                    {module: 'LocalModule1'}
                    {module: 'should'}
                    {module: 'LocalModule2'}

                ], []

            ).should.eql [

                'FakeLocalModule1'
                require 'should'
                'FakeLocalModule2'

            ]

            test done


        it 'arranges _arg for the focussed injection', (done) -> 

            services = [
                {module: 'mod0'}
                {module: 'mod1'}
                {
                    _nested: {
                        class2: ['Mod2', 'class2']
                        class3: ['Mod3', 'class3']
                        Mod4:   ['Mod4']  
                    }
                }
            ]

            preDefined = ['mod0', 'mod1']

            #
            # mock findModule
            #

            InjectorSupport.findModule = (config) -> 
                
                switch config.module

                    when 'Mod2' then return class2: 'class2'
                    when 'Mod3' then return class3: 'class3'
                    when 'Mod4' then return 'Mod4'

            services = InjectorSupport.loadServices( services, preDefined )

            services.should.eql [
                'mod0'
                'mod1'
                { 
                    Mod2: 'class2'
                    Mod3: 'class3'
                    Mod4: 'Mod4' 
                }
            ]


