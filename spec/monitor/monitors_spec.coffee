require('nez').realize 'Monitors', (Monitors, test, it) -> 

    it 'exports directory monitor', (done) ->

        Monitors.directory.should.equal require '../../lib/monitor/directory'
        test done
