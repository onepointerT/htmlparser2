Tokenizer = require('./Tokenizer.js')

###
	Options:

	xmlMode: Disables the special behavior for script/style tags (false by default)
	lowerCaseAttributeNames: call .toLowerCase for each attribute name (true if xmlMode is `false`)
	lowerCaseTags: call .toLowerCase for each tag name (true if xmlMode is `false`)
###

###
	Callbacks:

	oncdataend,
	oncdatastart,
	onclosetag,
	oncomment,
	oncommentend,
	onerror,
	onopentag,
	onprocessinginstruction,
	onreset,
	ontext
###

formTags = 
  input: true
  option: true
  optgroup: true
  select: true
  button: true
  datalist: true
  textarea: true
openImpliesClose = 
  tr:
    tr: true
    th: true
    td: true
  th: th: true
  td:
    thead: true
    th: true
    td: true
  body:
    head: true
    link: true
    script: true
  li: li: true
  p: p: true
  h1: p: true
  h2: p: true
  h3: p: true
  h4: p: true
  h5: p: true
  h6: p: true
  select: formTags
  input: formTags
  output: formTags
  button: formTags
  datalist: formTags
  textarea: formTags
  option: option: true
  optgroup: optgroup: true
voidElements = 
  __proto__: null
  area: true
  base: true
  basefont: true
  br: true
  col: true
  command: true
  embed: true
  frame: true
  hr: true
  img: true
  input: true
  isindex: true
  keygen: true
  link: true
  meta: true
  param: true
  source: true
  track: true
  wbr: true
foreignContextElements = 
  __proto__: null
  math: true
  svg: true
htmlIntegrationElements = 
  __proto__: null
  mi: true
  mo: true
  mn: true
  ms: true
  mtext: true
  'annotation-xml': true
  foreignObject: true
  desc: true
  title: true
re_nameEnd = /\s|\//

Parser = (cbs, options) ->
  @_options = options or {}
  @_cbs = cbs or {}
  @_tagname = ''
  @_attribname = ''
  @_attribvalue = ''
  @_attribs = null
  @_stack = []
  @_foreignContext = []
  @startIndex = 0
  @endIndex = null
  @_lowerCaseTagNames = if 'lowerCaseTags' of @_options then ! !@_options.lowerCaseTags else !@_options.xmlMode
  @_lowerCaseAttributeNames = if 'lowerCaseAttributeNames' of @_options then ! !@_options.lowerCaseAttributeNames else !@_options.xmlMode
  if @_options.Tokenizer
    Tokenizer = @_options.Tokenizer
  @_tokenizer = new Tokenizer(@_options, this)
  if @_cbs.onparserinit
    @_cbs.onparserinit this
  return

require('inherits') Parser, require('events').EventEmitter

Parser::_updatePosition = (initialOffset) ->
  if @endIndex == null
    if @_tokenizer._sectionStart <= initialOffset
      @startIndex = 0
    else
      @startIndex = @_tokenizer._sectionStart - initialOffset
  else
    @startIndex = @endIndex + 1
  @endIndex = @_tokenizer.getAbsoluteIndex()
  return

#Tokenizer event handlers

Parser::ontext = (data) ->
  @_updatePosition 1
  @endIndex--
  if @_cbs.ontext
    @_cbs.ontext data
  return

Parser::onopentagname = (name) ->
  if @_lowerCaseTagNames
    name = name.toLowerCase()
  @_tagname = name
  if !@_options.xmlMode and name of openImpliesClose
    el = undefined
    while (el = @_stack[@_stack.length - 1]) of openImpliesClose[name]
      @onclosetag el
  if @_options.xmlMode or !(name of voidElements)
    @_stack.push name
    if name of foreignContextElements
      @_foreignContext.push true
    else if name of htmlIntegrationElements
      @_foreignContext.push false
  if @_cbs.onopentagname
    @_cbs.onopentagname name
  if @_cbs.onopentag
    @_attribs = {}
  return

Parser::onopentagend = ->
  @_updatePosition 1
  if @_attribs
    if @_cbs.onopentag
      @_cbs.onopentag @_tagname, @_attribs
    @_attribs = null
  if !@_options.xmlMode and @_cbs.onclosetag and @_tagname of voidElements
    @_cbs.onclosetag @_tagname
  @_tagname = ''
  return

Parser::onclosetag = (name) ->
  @_updatePosition 1
  if @_lowerCaseTagNames
    name = name.toLowerCase()
  if @_stack.length and (!(name of voidElements) or @_options.xmlMode)
    pos = @_stack.lastIndexOf(name)
    if pos != -1
      if @_cbs.onclosetag
        pos = @_stack.length - pos
        while pos--
          @_cbs.onclosetag @_stack.pop()
      else
        @_stack.length = pos
    else if name == 'p' and !@_options.xmlMode
      @onopentagname name
      @_closeCurrentTag()
  else if !@_options.xmlMode and (name == 'br' or name == 'p')
    @onopentagname name
    @_closeCurrentTag()
  return

Parser::onselfclosingtag = ->
  if @_options.xmlMode or @_options.recognizeSelfClosing or @_foreignContext[@_foreignContext.length - 1]
    @_closeCurrentTag()
  else
    @onopentagend()
  return

Parser::_closeCurrentTag = ->
  name = @_tagname
  @onopentagend()
  #self-closing tags will be on the top of the stack
  #(cheaper check than in onclosetag)
  if @_stack[@_stack.length - 1] == name
    if @_cbs.onclosetag
      @_cbs.onclosetag name
    @_stack.pop()
    if name of foreignContextElements or name of htmlIntegrationElements
      @_foreignContext.pop()
  return

Parser::onattribname = (name) ->
  if @_lowerCaseAttributeNames
    name = name.toLowerCase()
  @_attribname = name
  return

Parser::onattribdata = (value) ->
  @_attribvalue += value
  return

Parser::onattribend = ->
  if @_cbs.onattribute
    @_cbs.onattribute @_attribname, @_attribvalue
  if @_attribs and !Object::hasOwnProperty.call(@_attribs, @_attribname)
    @_attribs[@_attribname] = @_attribvalue
  @_attribname = ''
  @_attribvalue = ''
  return

Parser::_getInstructionName = (value) ->
  idx = value.search(re_nameEnd)
  name = if idx < 0 then value else value.substr(0, idx)
  if @_lowerCaseTagNames
    name = name.toLowerCase()
  name

Parser::ondeclaration = (value) ->
  if @_cbs.onprocessinginstruction
    name = @_getInstructionName(value)
    @_cbs.onprocessinginstruction '!' + name, '!' + value
  return

Parser::onprocessinginstruction = (value) ->
  if @_cbs.onprocessinginstruction
    name = @_getInstructionName(value)
    @_cbs.onprocessinginstruction '?' + name, '?' + value
  return

Parser::oncomment = (value) ->
  @_updatePosition 4
  if @_cbs.oncomment
    @_cbs.oncomment value
  if @_cbs.oncommentend
    @_cbs.oncommentend()
  return

Parser::oncdata = (value) ->
  @_updatePosition 1
  if @_options.xmlMode or @_options.recognizeCDATA
    if @_cbs.oncdatastart
      @_cbs.oncdatastart()
    if @_cbs.ontext
      @_cbs.ontext value
    if @_cbs.oncdataend
      @_cbs.oncdataend()
  else
    @oncomment '[CDATA[' + value + ']]'
  return

Parser::onerror = (err) ->
  if @_cbs.onerror
    @_cbs.onerror err
  return

Parser::onend = ->
  if @_cbs.onclosetag
    i = @_stack.length
    while i > 0
      @_cbs.onclosetag @_stack[--i]
  if @_cbs.onend
    @_cbs.onend()
  return

#Resets the parser to a blank state, ready to parse a new HTML document

Parser::reset = ->
  if @_cbs.onreset
    @_cbs.onreset()
  @_tokenizer.reset()
  @_tagname = ''
  @_attribname = ''
  @_attribs = null
  @_stack = []
  if @_cbs.onparserinit
    @_cbs.onparserinit this
  return

#Parses a complete HTML document and pushes it to the handler

Parser::parseComplete = (data) ->
  @reset()
  @end data
  return

Parser::write = (chunk) ->
  @_tokenizer.write chunk
  return

Parser::end = (chunk) ->
  @_tokenizer.end chunk
  return

Parser::pause = ->
  @_tokenizer.pause()
  return

Parser::resume = ->
  @_tokenizer.resume()
  return

#alias for backwards compat
Parser::parseChunk = Parser::write
Parser::done = Parser::end
module.exports = Parser
