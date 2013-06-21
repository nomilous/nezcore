require('nez').realize 'Monitor', (Monitor, test, it) -> 

    it 'exports directory monitor', (done) ->

        Monitor.directory.should.equal require '../../lib/monitor/directory'
        test done
