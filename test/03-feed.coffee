#Runs tests for feeds
helper = require('./test-helper.js')
FeedHandler = require('..').RssHandler
fs = require('fs')
path = require('path')
helper.mochaTest 'Feeds', __dirname, (test, cb) ->
  fs.readFile path.join(__dirname, 'Documents', test.file), (err, file) ->
    helper.writeToParser new FeedHandler(cb), { xmlMode: true }, file.toString()
    return
  return
