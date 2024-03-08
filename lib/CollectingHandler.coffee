CollectingHandler = (cbs) ->
  @_cbs = cbs or {}
  @events = []
  return

module.exports = CollectingHandler
EVENTS = require('./').EVENTS
Object.keys(EVENTS).forEach (name) ->
  if EVENTS[name] == 0
    name = 'on' + name

    CollectingHandler.prototype[name] = ->
      @events.push [ name ]
      if @_cbs[name]
        @_cbs[name]()
      return

  else if EVENTS[name] == 1
    name = 'on' + name

    CollectingHandler.prototype[name] = (a) ->
      @events.push [
        name
        a
      ]
      if @_cbs[name]
        @_cbs[name] a
      return

  else if EVENTS[name] == 2
    name = 'on' + name

    CollectingHandler.prototype[name] = (a, b) ->
      @events.push [
        name
        a
        b
      ]
      if @_cbs[name]
        @_cbs[name] a, b
      return

  else
    throw Error('wrong number of arguments')
  return

CollectingHandler::onreset = ->
  @events = []
  if @_cbs.onreset
    @_cbs.onreset()
  return

CollectingHandler::restart = ->
  if @_cbs.onreset
    @_cbs.onreset()
  i = 0
  len = @events.length
  while i < len
    if @_cbs[@events[i][0]]
      num = @events[i].length
      if num == 1
        @_cbs[@events[i][0]]()
      else if num == 2
        @_cbs[@events[i][0]] @events[i][1]
      else
        @_cbs[@events[i][0]] @events[i][1], @events[i][2]
    i++
  return
