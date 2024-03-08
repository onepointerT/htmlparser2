index = require('./index.js')
DomHandler = index.DomHandler
DomUtils = index.DomUtils
#TODO: make this a streamable handler

FeedHandler = (callback, options) ->
  @init callback, options
  return

getElements = (what, where) ->
  DomUtils.getElementsByTagName what, where, true

getOneElement = (what, where) ->
  DomUtils.getElementsByTagName(what, where, true, 1)[0]

fetch = (what, where, recurse) ->
  DomUtils.getText(DomUtils.getElementsByTagName(what, where, recurse, 1)).trim()

addConditionally = (obj, prop, what, where, recurse) ->
  tmp = fetch(what, where, recurse)
  if tmp
    obj[prop] = tmp
  return

require('inherits') FeedHandler, DomHandler
FeedHandler::init = DomHandler

isValidFeed = (value) ->
  value == 'rss' or value == 'feed' or value == 'rdf:RDF'

FeedHandler::onend = ->
  feed = {}
  feedRoot = getOneElement(isValidFeed, @dom)
  tmp = undefined
  childs = undefined
  if feedRoot
    if feedRoot.name == 'feed'
      childs = feedRoot.children
      feed.type = 'atom'
      addConditionally feed, 'id', 'id', childs
      addConditionally feed, 'title', 'title', childs
      if (tmp = getOneElement('link', childs)) and (tmp = tmp.attribs) and (tmp = tmp.href)
        feed.link = tmp
      addConditionally feed, 'description', 'subtitle', childs
      if tmp = fetch('updated', childs)
        feed.updated = new Date(tmp)
      addConditionally feed, 'author', 'email', childs, true
      feed.items = getElements('entry', childs).map((item) ->
        `var tmp`
        entry = {}
        tmp = undefined
        item = item.children
        addConditionally entry, 'id', 'id', item
        addConditionally entry, 'title', 'title', item
        if (tmp = getOneElement('link', item)) and (tmp = tmp.attribs) and (tmp = tmp.href)
          entry.link = tmp
        if tmp = fetch('summary', item) or fetch('content', item)
          entry.description = tmp
        if tmp = fetch('updated', item)
          entry.pubDate = new Date(tmp)
        entry
      )
    else
      childs = getOneElement('channel', feedRoot.children).children
      feed.type = feedRoot.name.substr(0, 3)
      feed.id = ''
      addConditionally feed, 'title', 'title', childs
      addConditionally feed, 'link', 'link', childs
      addConditionally feed, 'description', 'description', childs
      if tmp = fetch('lastBuildDate', childs)
        feed.updated = new Date(tmp)
      addConditionally feed, 'author', 'managingEditor', childs, true
      feed.items = getElements('item', feedRoot.children).map((item) ->
        `var tmp`
        entry = {}
        tmp = undefined
        item = item.children
        addConditionally entry, 'id', 'guid', item
        addConditionally entry, 'title', 'title', item
        addConditionally entry, 'link', 'link', item
        addConditionally entry, 'description', 'description', item
        if tmp = fetch('pubDate', item)
          entry.pubDate = new Date(tmp)
        entry
      )
  @dom = feed
  DomHandler::_handleCallback.call this, if feedRoot then null else Error('couldn\'t find root of feed')
  return

module.exports = FeedHandler
