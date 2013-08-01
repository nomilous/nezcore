#
# create before() and after() for hook registration
#

beforeHooks = each: [], all: []
afterHooks  = each: [], all: []

Object.defineProperty global, 'before',
    enumerable: false
    get: -> (opts = {}) -> 
        beforeHooks.each.push opts.each if typeof opts.each == 'function'
        beforeHooks.all.push  opts.all  if typeof opts.all  == 'function'


Object.defineProperty global, 'after',
    enumerable: false
    get: -> (opts = {}) -> 
        afterHooks.each.push opts.each if typeof opts.each == 'function'
        afterHooks.all.push  opts.all  if typeof opts.all  == 'function'


module.exports = 

    beforeAll: (opts, control) -> 

        (done, inject) -> 

            #
            # assign registered hooks
            #

            beforeEach = beforeHooks.each.pop()
            beforeAll  = beforeHooks.all.pop() 
            afterEach  = afterHooks.each.pop() 
            afterAll   = afterHooks.all.pop()

            control.beforeEach ||= beforeEach
            control.beforeAll  ||= beforeAll
            control.afterEach  ||= afterEach
            control.afterAll   ||= afterAll

            if typeof control.beforeAll == 'function'

                return control.beforeAll done unless opts.global
                return control.beforeAll.call null, done

            done()

