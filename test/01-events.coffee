helper = require('./test-helper.js')
helper.mochaTest 'Events', __dirname, (test, cb) ->
  helper.writeToParser helper.getEventCollector(cb), test.options.parser, test.html
  return
