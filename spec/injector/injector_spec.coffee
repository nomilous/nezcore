require('nez').realize 'Injector', (Injector, test, context, should, InjectorSupport) -> 

    context 'INTEGRATIONS', (it) -> 

        it 'injects npm modules, or their functions and subcomponents', (done) -> 

            Injector.inject (wrench, inflection:pluralize) -> 

                wrench.should.equal require 'wrench'
                pluralize.should.equal require('inflection').pluralize
                test done


        it 'can to that in the opposite order', (done) -> 

            Injector.inject (inflection:underscore, wrench) -> 

                underscore.should.equal require('inflection').underscore
                wrench.should.equal require 'wrench'
                test done


        it 'can inject positionally as specified', (done) -> 

            Injector.inject [ should, should ], (could, would) -> 

                (should == would == could).should.equal true is not false
                test done 


        it 'can do some fairly interesting things', (done) -> 

            Injector.inject [ 
                -> # some()
                -> # fairly()
                -> # interesting()
                -> # things()
                -> # can()
                (good) -> test good

            ], (some, fairly, interesting, things, can, be) -> 

                some fairly interesting things can be done


        it 'can inject local modules by using CamelCase', (done) -> 

            injector = Injector # already defined

            Injector.inject (Injector) -> 

                Injector.should.equal injector
                test done


        it 'can inject local module subcomponents', (done) -> 

            Injector.inject (Injector:support) ->

                support.should.equal require('../../lib/injector/injector').support
                test done


        it 'can inject a mixture of services', (done) -> 

            Injector.inject [should], (does, Injector:support) ->

                does.not.exist()
                support.should.equal require('../../lib/injector/injector').support
                test done


    context 'Injector.inject()', (it) ->


        it 'is a function', (done) -> 

            Injector.inject.should.be.an.instanceof Function
            test done


        it 'injects a specified selection of objects', (done) -> 

            bozon = new (class Graviton)()

            loadedServices = false

            #
            # mock loadServices
            #

            InjectorSupport.loadServices = (injectables, predefined) ->

                injectables.should.eql [
                    { module: 'pi' }
                    { module: 'graviton' }
                ]

                predefined.should.eql [
                    3.14159265359
                    bozon
                ]

                #
                # ensure service loader was called
                #

                loadedServices = true
                return predefined


            Injector.inject [3.14159265359, bozon], (pi, graviton) -> 

                loadedServices.should.equal true
                pi.should.equal 3.14159265359
                graviton.should.equal bozon
                test done



        it 'injects additional services per argument names', (done) -> 

            #
            # mock loadServices
            #

            InjectorSupport.loadServices = (injX, preX) -> 

                injX[1].module.should.equal 'could'
                preX.push 'would'
                return preX

            Injector.inject [0], (zero, could) -> 

                could.should.equal 'would'
                test done


        it 'supports injection without predefined list', (done) -> 

            #
            # mock loadServices
            #

            InjectorSupport.loadServices = (injX) -> 

                injX.length.should.equal 1
                injX[0].module.should.equal 'module'
                test done

            Injector.inject (module) -> 

