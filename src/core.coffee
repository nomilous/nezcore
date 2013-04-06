module.exports = core =

    #
    # logger
    #

    logger: require './logger/logger'


    #
    # runtime / cli bits
    #

    runtime: require './runtime/runtime'


    #
    # for runtime injection
    #

    injector: require './injector/injector'


    #
    # for configuration
    #

    config: require './config/config'

    