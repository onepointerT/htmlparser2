ProxyHandler = (cbs) ->
  @_cbs = cbs or {}
  return

module.exports = ProxyHandler
EVENTS = require('./').EVENTS
Object.keys(EVENTS).forEach (name) ->
  if EVENTS[name] == 0
    name = 'on' + name

    ProxyHandler.prototype[name] = ->
      if @_cbs[name]
        @_cbs[name]()
      return

  else if EVENTS[name] == 1
    name = 'on' + name

    ProxyHandler.prototype[name] = (a) ->
      if @_cbs[name]
        @_cbs[name] a
      return

  else if EVENTS[name] == 2
    name = 'on' + name

    ProxyHandler.prototype[name] = (a, b) ->
      if @_cbs[name]
        @_cbs[name] a, b
      return

  else
    throw Error('wrong number of arguments')
  return
