Stream = (options) ->
  Parser.call this, new Cbs(this), options
  return

Cbs = (scope) ->
  @scope = scope
  return

module.exports = Stream
Parser = require('./WritableStream.js')
require('inherits') Stream, Parser
Stream::readable = true
EVENTS = require('../').EVENTS
Object.keys(EVENTS).forEach (name) ->
  if EVENTS[name] == 0

    Cbs.prototype['on' + name] = ->
      @scope.emit name
      return

  else if EVENTS[name] == 1

    Cbs.prototype['on' + name] = (a) ->
      @scope.emit name, a
      return

  else if EVENTS[name] == 2

    Cbs.prototype['on' + name] = (a, b) ->
      @scope.emit name, a, b
      return

  else
    throw Error('wrong number of arguments!')
  return
