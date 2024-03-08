htmlparser2 = require('..')
fs = require('fs')
path = require('path')
assert = require('assert')
Parser = htmlparser2.Parser
CollectingHandler = htmlparser2.CollectingHandler

eventReducer = (events, arr) ->
  if arr[0] == 'onerror' or arr[0] == 'onend'
      else if arr[0] == 'ontext' and events.length and events[events.length - 1].event == 'text'
    events[events.length - 1].data[0] += arr[1]
  else
    events.push
      event: arr[0].substr(2)
      data: arr.slice(1)
  events

getCallback = (expected, done) ->
  repeated = false
  (err, actual) ->
    assert.ifError err
    try
      assert.deepEqual expected, actual, 'didn\'t get expected output'
    catch e
      e.expected = JSON.stringify(expected, null, 2)
      e.actual = JSON.stringify(actual, null, 2)
      throw e
    if repeated
      done()
    else
      repeated = true
    return

exports.writeToParser = (handler, options, data) ->
  parser = new Parser(handler, options)
  #first, try to run the test via chunks
  i = 0
  while i < data.length
    parser.write data.charAt(i)
    i++
  parser.end()
  #then parse everything
  parser.parseComplete data
  return

#returns a tree structure

exports.getEventCollector = (cb) ->
  handler = new CollectingHandler(
    onerror: cb
    onend: onend)

  onend = ->
    cb null, handler.events.reduce(eventReducer, [])
    return

  handler

exports.mochaTest = (name, root, test) ->

  readDir = ->
    dir = path.join(root, name)
    fs.readdirSync(dir).filter(RegExp::test, /^[^._]/).map((name) ->
      path.join dir, name
    ).map(require).forEach runTest
    return

  runTest = (file) ->
    it file.name, (done) ->
      test file, getCallback(file.expected, done)
      return
    return

  describe name, readDir
  return
