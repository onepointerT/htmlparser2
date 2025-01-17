helper = require('./test-helper.js')
Stream = require('..').WritableStream
fs = require('fs')
path = require('path')
helper.mochaTest 'Stream', __dirname, (test, cb) ->
  filePath = path.join(__dirname, 'Documents', test.file)
  fs.createReadStream(filePath).pipe(new Stream(helper.getEventCollector((err, events) ->
    cb err, events
    handler = helper.getEventCollector(cb)
    stream = new Stream(handler, test.options)
    fs.readFile filePath, (err, data) ->
      if err
        throw err
      else
        stream.end data
      return
    return
  ), test.options)).on 'error', cb
  return
