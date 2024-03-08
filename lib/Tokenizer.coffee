whitespace = (c) ->
  c == ' ' or c == '\n' or c == '\u0009' or c == '\u000c' or c == '\u000d'

ifElseState = (upper, SUCCESS, FAILURE) ->
  lower = upper.toLowerCase()
  if upper == lower
    (c) ->
      if c == lower
        @_state = SUCCESS
      else
        @_state = FAILURE
        @_index--
      return
  else
    (c) ->
      if c == lower or c == upper
        @_state = SUCCESS
      else
        @_state = FAILURE
        @_index--
      return

consumeSpecialNameChar = (upper, NEXT_STATE) ->
  lower = upper.toLowerCase()
  (c) ->
    if c == lower or c == upper
      @_state = NEXT_STATE
    else
      @_state = IN_TAG_NAME
      @_index--
      #consume the token again
    return

Tokenizer = (options, cbs) ->
  @_state = TEXT
  @_buffer = ''
  @_sectionStart = 0
  @_index = 0
  @_bufferOffset = 0
  #chars removed from _buffer
  @_baseState = TEXT
  @_special = SPECIAL_NONE
  @_cbs = cbs
  @_running = true
  @_ended = false
  @_xmlMode = ! !(options and options.xmlMode)
  @_decodeEntities = ! !(options and options.decodeEntities)
  return

module.exports = Tokenizer
decodeCodePoint = require('entities/lib/decode_codepoint.js')
entityMap = require('entities/maps/entities.json')
legacyMap = require('entities/maps/legacy.json')
xmlMap = require('entities/maps/xml.json')
i = 0
TEXT = i++
BEFORE_TAG_NAME = i++
#after <
IN_TAG_NAME = i++
IN_SELF_CLOSING_TAG = i++
BEFORE_CLOSING_TAG_NAME = i++
IN_CLOSING_TAG_NAME = i++
AFTER_CLOSING_TAG_NAME = i++
#attributes
BEFORE_ATTRIBUTE_NAME = i++
IN_ATTRIBUTE_NAME = i++
AFTER_ATTRIBUTE_NAME = i++
BEFORE_ATTRIBUTE_VALUE = i++
IN_ATTRIBUTE_VALUE_DQ = i++
# "
IN_ATTRIBUTE_VALUE_SQ = i++
# '
IN_ATTRIBUTE_VALUE_NQ = i++
#declarations
BEFORE_DECLARATION = i++
# !
IN_DECLARATION = i++
#processing instructions
IN_PROCESSING_INSTRUCTION = i++
# ?
#comments
BEFORE_COMMENT = i++
IN_COMMENT = i++
AFTER_COMMENT_1 = i++
AFTER_COMMENT_2 = i++
#cdata
BEFORE_CDATA_1 = i++
# [
BEFORE_CDATA_2 = i++
# C
BEFORE_CDATA_3 = i++
# D
BEFORE_CDATA_4 = i++
# A
BEFORE_CDATA_5 = i++
# T
BEFORE_CDATA_6 = i++
# A
IN_CDATA = i++
# [
AFTER_CDATA_1 = i++
# ]
AFTER_CDATA_2 = i++
# ]
#special tags
BEFORE_SPECIAL = i++
#S
BEFORE_SPECIAL_END = i++
#S
BEFORE_SCRIPT_1 = i++
#C
BEFORE_SCRIPT_2 = i++
#R
BEFORE_SCRIPT_3 = i++
#I
BEFORE_SCRIPT_4 = i++
#P
BEFORE_SCRIPT_5 = i++
#T
AFTER_SCRIPT_1 = i++
#C
AFTER_SCRIPT_2 = i++
#R
AFTER_SCRIPT_3 = i++
#I
AFTER_SCRIPT_4 = i++
#P
AFTER_SCRIPT_5 = i++
#T
BEFORE_STYLE_1 = i++
#T
BEFORE_STYLE_2 = i++
#Y
BEFORE_STYLE_3 = i++
#L
BEFORE_STYLE_4 = i++
#E
AFTER_STYLE_1 = i++
#T
AFTER_STYLE_2 = i++
#Y
AFTER_STYLE_3 = i++
#L
AFTER_STYLE_4 = i++
#E
BEFORE_ENTITY = i++
#&
BEFORE_NUMERIC_ENTITY = i++
##
IN_NAMED_ENTITY = i++
IN_NUMERIC_ENTITY = i++
IN_HEX_ENTITY = i++
#X
j = 0
SPECIAL_NONE = j++
SPECIAL_SCRIPT = j++
SPECIAL_STYLE = j++

Tokenizer::_stateText = (c) ->
  if c == '<'
    if @_index > @_sectionStart
      @_cbs.ontext @_getSection()
    @_state = BEFORE_TAG_NAME
    @_sectionStart = @_index
  else if @_decodeEntities and @_special == SPECIAL_NONE and c == '&'
    if @_index > @_sectionStart
      @_cbs.ontext @_getSection()
    @_baseState = TEXT
    @_state = BEFORE_ENTITY
    @_sectionStart = @_index
  return

Tokenizer::_stateBeforeTagName = (c) ->
  if c == '/'
    @_state = BEFORE_CLOSING_TAG_NAME
  else if c == '<'
    @_cbs.ontext @_getSection()
    @_sectionStart = @_index
  else if c == '>' or @_special != SPECIAL_NONE or whitespace(c)
    @_state = TEXT
  else if c == '!'
    @_state = BEFORE_DECLARATION
    @_sectionStart = @_index + 1
  else if c == '?'
    @_state = IN_PROCESSING_INSTRUCTION
    @_sectionStart = @_index + 1
  else
    @_state = if !@_xmlMode and (c == 's' or c == 'S') then BEFORE_SPECIAL else IN_TAG_NAME
    @_sectionStart = @_index
  return

Tokenizer::_stateInTagName = (c) ->
  if c == '/' or c == '>' or whitespace(c)
    @_emitToken 'onopentagname'
    @_state = BEFORE_ATTRIBUTE_NAME
    @_index--
  return

Tokenizer::_stateBeforeCloseingTagName = (c) ->
  if whitespace(c)
      else if c == '>'
    @_state = TEXT
  else if @_special != SPECIAL_NONE
    if c == 's' or c == 'S'
      @_state = BEFORE_SPECIAL_END
    else
      @_state = TEXT
      @_index--
  else
    @_state = IN_CLOSING_TAG_NAME
    @_sectionStart = @_index
  return

Tokenizer::_stateInCloseingTagName = (c) ->
  if c == '>' or whitespace(c)
    @_emitToken 'onclosetag'
    @_state = AFTER_CLOSING_TAG_NAME
    @_index--
  return

Tokenizer::_stateAfterCloseingTagName = (c) ->
  #skip everything until ">"
  if c == '>'
    @_state = TEXT
    @_sectionStart = @_index + 1
  return

Tokenizer::_stateBeforeAttributeName = (c) ->
  if c == '>'
    @_cbs.onopentagend()
    @_state = TEXT
    @_sectionStart = @_index + 1
  else if c == '/'
    @_state = IN_SELF_CLOSING_TAG
  else if !whitespace(c)
    @_state = IN_ATTRIBUTE_NAME
    @_sectionStart = @_index
  return

Tokenizer::_stateInSelfClosingTag = (c) ->
  if c == '>'
    @_cbs.onselfclosingtag()
    @_state = TEXT
    @_sectionStart = @_index + 1
  else if !whitespace(c)
    @_state = BEFORE_ATTRIBUTE_NAME
    @_index--
  return

Tokenizer::_stateInAttributeName = (c) ->
  if c == '=' or c == '/' or c == '>' or whitespace(c)
    @_cbs.onattribname @_getSection()
    @_sectionStart = -1
    @_state = AFTER_ATTRIBUTE_NAME
    @_index--
  return

Tokenizer::_stateAfterAttributeName = (c) ->
  if c == '='
    @_state = BEFORE_ATTRIBUTE_VALUE
  else if c == '/' or c == '>'
    @_cbs.onattribend()
    @_state = BEFORE_ATTRIBUTE_NAME
    @_index--
  else if !whitespace(c)
    @_cbs.onattribend()
    @_state = IN_ATTRIBUTE_NAME
    @_sectionStart = @_index
  return

Tokenizer::_stateBeforeAttributeValue = (c) ->
  if c == '"'
    @_state = IN_ATTRIBUTE_VALUE_DQ
    @_sectionStart = @_index + 1
  else if c == '\''
    @_state = IN_ATTRIBUTE_VALUE_SQ
    @_sectionStart = @_index + 1
  else if !whitespace(c)
    @_state = IN_ATTRIBUTE_VALUE_NQ
    @_sectionStart = @_index
    @_index--
    #reconsume token
  return

Tokenizer::_stateInAttributeValueDoubleQuotes = (c) ->
  if c == '"'
    @_emitToken 'onattribdata'
    @_cbs.onattribend()
    @_state = BEFORE_ATTRIBUTE_NAME
  else if @_decodeEntities and c == '&'
    @_emitToken 'onattribdata'
    @_baseState = @_state
    @_state = BEFORE_ENTITY
    @_sectionStart = @_index
  return

Tokenizer::_stateInAttributeValueSingleQuotes = (c) ->
  if c == '\''
    @_emitToken 'onattribdata'
    @_cbs.onattribend()
    @_state = BEFORE_ATTRIBUTE_NAME
  else if @_decodeEntities and c == '&'
    @_emitToken 'onattribdata'
    @_baseState = @_state
    @_state = BEFORE_ENTITY
    @_sectionStart = @_index
  return

Tokenizer::_stateInAttributeValueNoQuotes = (c) ->
  if whitespace(c) or c == '>'
    @_emitToken 'onattribdata'
    @_cbs.onattribend()
    @_state = BEFORE_ATTRIBUTE_NAME
    @_index--
  else if @_decodeEntities and c == '&'
    @_emitToken 'onattribdata'
    @_baseState = @_state
    @_state = BEFORE_ENTITY
    @_sectionStart = @_index
  return

Tokenizer::_stateBeforeDeclaration = (c) ->
  @_state = if c == '[' then BEFORE_CDATA_1 else if c == '-' then BEFORE_COMMENT else IN_DECLARATION
  return

Tokenizer::_stateInDeclaration = (c) ->
  if c == '>'
    @_cbs.ondeclaration @_getSection()
    @_state = TEXT
    @_sectionStart = @_index + 1
  return

Tokenizer::_stateInProcessingInstruction = (c) ->
  if c == '>'
    @_cbs.onprocessinginstruction @_getSection()
    @_state = TEXT
    @_sectionStart = @_index + 1
  return

Tokenizer::_stateBeforeComment = (c) ->
  if c == '-'
    @_state = IN_COMMENT
    @_sectionStart = @_index + 1
  else
    @_state = IN_DECLARATION
  return

Tokenizer::_stateInComment = (c) ->
  if c == '-'
    @_state = AFTER_COMMENT_1
  return

Tokenizer::_stateAfterComment1 = (c) ->
  if c == '-'
    @_state = AFTER_COMMENT_2
  else
    @_state = IN_COMMENT
  return

Tokenizer::_stateAfterComment2 = (c) ->
  if c == '>'
    #remove 2 trailing chars
    @_cbs.oncomment @_buffer.substring(@_sectionStart, @_index - 2)
    @_state = TEXT
    @_sectionStart = @_index + 1
  else if c != '-'
    @_state = IN_COMMENT
  # else: stay in AFTER_COMMENT_2 (`--->`)
  return

Tokenizer::_stateBeforeCdata1 = ifElseState('C', BEFORE_CDATA_2, IN_DECLARATION)
Tokenizer::_stateBeforeCdata2 = ifElseState('D', BEFORE_CDATA_3, IN_DECLARATION)
Tokenizer::_stateBeforeCdata3 = ifElseState('A', BEFORE_CDATA_4, IN_DECLARATION)
Tokenizer::_stateBeforeCdata4 = ifElseState('T', BEFORE_CDATA_5, IN_DECLARATION)
Tokenizer::_stateBeforeCdata5 = ifElseState('A', BEFORE_CDATA_6, IN_DECLARATION)

Tokenizer::_stateBeforeCdata6 = (c) ->
  if c == '['
    @_state = IN_CDATA
    @_sectionStart = @_index + 1
  else
    @_state = IN_DECLARATION
    @_index--
  return

Tokenizer::_stateInCdata = (c) ->
  if c == ']'
    @_state = AFTER_CDATA_1
  return

Tokenizer::_stateAfterCdata1 = (c) ->
  if c == ']'
    @_state = AFTER_CDATA_2
  else
    @_state = IN_CDATA
  return

Tokenizer::_stateAfterCdata2 = (c) ->
  if c == '>'
    #remove 2 trailing chars
    @_cbs.oncdata @_buffer.substring(@_sectionStart, @_index - 2)
    @_state = TEXT
    @_sectionStart = @_index + 1
  else if c != ']'
    @_state = IN_CDATA
  #else: stay in AFTER_CDATA_2 (`]]]>`)
  return

Tokenizer::_stateBeforeSpecial = (c) ->
  if c == 'c' or c == 'C'
    @_state = BEFORE_SCRIPT_1
  else if c == 't' or c == 'T'
    @_state = BEFORE_STYLE_1
  else
    @_state = IN_TAG_NAME
    @_index--
    #consume the token again
  return

Tokenizer::_stateBeforeSpecialEnd = (c) ->
  if @_special == SPECIAL_SCRIPT and (c == 'c' or c == 'C')
    @_state = AFTER_SCRIPT_1
  else if @_special == SPECIAL_STYLE and (c == 't' or c == 'T')
    @_state = AFTER_STYLE_1
  else
    @_state = TEXT
  return

Tokenizer::_stateBeforeScript1 = consumeSpecialNameChar('R', BEFORE_SCRIPT_2)
Tokenizer::_stateBeforeScript2 = consumeSpecialNameChar('I', BEFORE_SCRIPT_3)
Tokenizer::_stateBeforeScript3 = consumeSpecialNameChar('P', BEFORE_SCRIPT_4)
Tokenizer::_stateBeforeScript4 = consumeSpecialNameChar('T', BEFORE_SCRIPT_5)

Tokenizer::_stateBeforeScript5 = (c) ->
  if c == '/' or c == '>' or whitespace(c)
    @_special = SPECIAL_SCRIPT
  @_state = IN_TAG_NAME
  @_index--
  #consume the token again
  return

Tokenizer::_stateAfterScript1 = ifElseState('R', AFTER_SCRIPT_2, TEXT)
Tokenizer::_stateAfterScript2 = ifElseState('I', AFTER_SCRIPT_3, TEXT)
Tokenizer::_stateAfterScript3 = ifElseState('P', AFTER_SCRIPT_4, TEXT)
Tokenizer::_stateAfterScript4 = ifElseState('T', AFTER_SCRIPT_5, TEXT)

Tokenizer::_stateAfterScript5 = (c) ->
  if c == '>' or whitespace(c)
    @_special = SPECIAL_NONE
    @_state = IN_CLOSING_TAG_NAME
    @_sectionStart = @_index - 6
    @_index--
    #reconsume the token
  else
    @_state = TEXT
  return

Tokenizer::_stateBeforeStyle1 = consumeSpecialNameChar('Y', BEFORE_STYLE_2)
Tokenizer::_stateBeforeStyle2 = consumeSpecialNameChar('L', BEFORE_STYLE_3)
Tokenizer::_stateBeforeStyle3 = consumeSpecialNameChar('E', BEFORE_STYLE_4)

Tokenizer::_stateBeforeStyle4 = (c) ->
  if c == '/' or c == '>' or whitespace(c)
    @_special = SPECIAL_STYLE
  @_state = IN_TAG_NAME
  @_index--
  #consume the token again
  return

Tokenizer::_stateAfterStyle1 = ifElseState('Y', AFTER_STYLE_2, TEXT)
Tokenizer::_stateAfterStyle2 = ifElseState('L', AFTER_STYLE_3, TEXT)
Tokenizer::_stateAfterStyle3 = ifElseState('E', AFTER_STYLE_4, TEXT)

Tokenizer::_stateAfterStyle4 = (c) ->
  if c == '>' or whitespace(c)
    @_special = SPECIAL_NONE
    @_state = IN_CLOSING_TAG_NAME
    @_sectionStart = @_index - 5
    @_index--
    #reconsume the token
  else
    @_state = TEXT
  return

Tokenizer::_stateBeforeEntity = ifElseState('#', BEFORE_NUMERIC_ENTITY, IN_NAMED_ENTITY)
Tokenizer::_stateBeforeNumericEntity = ifElseState('X', IN_HEX_ENTITY, IN_NUMERIC_ENTITY)
#for entities terminated with a semicolon

Tokenizer::_parseNamedEntityStrict = ->
  #offset = 1
  if @_sectionStart + 1 < @_index
    entity = @_buffer.substring(@_sectionStart + 1, @_index)
    map = if @_xmlMode then xmlMap else entityMap
    if map.hasOwnProperty(entity)
      @_emitPartial map[entity]
      @_sectionStart = @_index + 1
  return

#parses legacy entities (without trailing semicolon)

Tokenizer::_parseLegacyEntity = ->
  start = @_sectionStart + 1
  limit = @_index - start
  if limit > 6
    limit = 6
  #the max length of legacy entities is 6
  while limit >= 2
    #the min length of legacy entities is 2
    entity = @_buffer.substr(start, limit)
    if legacyMap.hasOwnProperty(entity)
      @_emitPartial legacyMap[entity]
      @_sectionStart += limit + 1
      return
    else
      limit--
  return

Tokenizer::_stateInNamedEntity = (c) ->
  if c == ';'
    @_parseNamedEntityStrict()
    if @_sectionStart + 1 < @_index and !@_xmlMode
      @_parseLegacyEntity()
    @_state = @_baseState
  else if (c < 'a' or c > 'z') and (c < 'A' or c > 'Z') and (c < '0' or c > '9')
    if @_xmlMode
          else if @_sectionStart + 1 == @_index
          else if @_baseState != TEXT
      if c != '='
        @_parseNamedEntityStrict()
    else
      @_parseLegacyEntity()
    @_state = @_baseState
    @_index--
  return

Tokenizer::_decodeNumericEntity = (offset, base) ->
  sectionStart = @_sectionStart + offset
  if sectionStart != @_index
    #parse entity
    entity = @_buffer.substring(sectionStart, @_index)
    parsed = parseInt(entity, base)
    @_emitPartial decodeCodePoint(parsed)
    @_sectionStart = @_index
  else
    @_sectionStart--
  @_state = @_baseState
  return

Tokenizer::_stateInNumericEntity = (c) ->
  if c == ';'
    @_decodeNumericEntity 2, 10
    @_sectionStart++
  else if c < '0' or c > '9'
    if !@_xmlMode
      @_decodeNumericEntity 2, 10
    else
      @_state = @_baseState
    @_index--
  return

Tokenizer::_stateInHexEntity = (c) ->
  if c == ';'
    @_decodeNumericEntity 3, 16
    @_sectionStart++
  else if (c < 'a' or c > 'f') and (c < 'A' or c > 'F') and (c < '0' or c > '9')
    if !@_xmlMode
      @_decodeNumericEntity 3, 16
    else
      @_state = @_baseState
    @_index--
  return

Tokenizer::_cleanup = ->
  if @_sectionStart < 0
    @_buffer = ''
    @_bufferOffset += @_index
    @_index = 0
  else if @_running
    if @_state == TEXT
      if @_sectionStart != @_index
        @_cbs.ontext @_buffer.substr(@_sectionStart)
      @_buffer = ''
      @_bufferOffset += @_index
      @_index = 0
    else if @_sectionStart == @_index
      #the section just started
      @_buffer = ''
      @_bufferOffset += @_index
      @_index = 0
    else
      #remove everything unnecessary
      @_buffer = @_buffer.substr(@_sectionStart)
      @_index -= @_sectionStart
      @_bufferOffset += @_sectionStart
    @_sectionStart = 0
  return

#TODO make events conditional

Tokenizer::write = (chunk) ->
  if @_ended
    @_cbs.onerror Error('.write() after done!')
  @_buffer += chunk
  @_parse()
  return

Tokenizer::_parse = ->
  while @_index < @_buffer.length and @_running
    c = @_buffer.charAt(@_index)
    if @_state == TEXT
      @_stateText c
    else if @_state == BEFORE_TAG_NAME
      @_stateBeforeTagName c
    else if @_state == IN_TAG_NAME
      @_stateInTagName c
    else if @_state == BEFORE_CLOSING_TAG_NAME
      @_stateBeforeCloseingTagName c
    else if @_state == IN_CLOSING_TAG_NAME
      @_stateInCloseingTagName c
    else if @_state == AFTER_CLOSING_TAG_NAME
      @_stateAfterCloseingTagName c
    else if @_state == IN_SELF_CLOSING_TAG
      @_stateInSelfClosingTag c
    else if @_state == BEFORE_ATTRIBUTE_NAME

      ###
      		*	attributes
      ###

      @_stateBeforeAttributeName c
    else if @_state == IN_ATTRIBUTE_NAME
      @_stateInAttributeName c
    else if @_state == AFTER_ATTRIBUTE_NAME
      @_stateAfterAttributeName c
    else if @_state == BEFORE_ATTRIBUTE_VALUE
      @_stateBeforeAttributeValue c
    else if @_state == IN_ATTRIBUTE_VALUE_DQ
      @_stateInAttributeValueDoubleQuotes c
    else if @_state == IN_ATTRIBUTE_VALUE_SQ
      @_stateInAttributeValueSingleQuotes c
    else if @_state == IN_ATTRIBUTE_VALUE_NQ
      @_stateInAttributeValueNoQuotes c
    else if @_state == BEFORE_DECLARATION

      ###
      		*	declarations
      ###

      @_stateBeforeDeclaration c
    else if @_state == IN_DECLARATION
      @_stateInDeclaration c
    else if @_state == IN_PROCESSING_INSTRUCTION

      ###
      		*	processing instructions
      ###

      @_stateInProcessingInstruction c
    else if @_state == BEFORE_COMMENT

      ###
      		*	comments
      ###

      @_stateBeforeComment c
    else if @_state == IN_COMMENT
      @_stateInComment c
    else if @_state == AFTER_COMMENT_1
      @_stateAfterComment1 c
    else if @_state == AFTER_COMMENT_2
      @_stateAfterComment2 c
    else if @_state == BEFORE_CDATA_1

      ###
      		*	cdata
      ###

      @_stateBeforeCdata1 c
    else if @_state == BEFORE_CDATA_2
      @_stateBeforeCdata2 c
    else if @_state == BEFORE_CDATA_3
      @_stateBeforeCdata3 c
    else if @_state == BEFORE_CDATA_4
      @_stateBeforeCdata4 c
    else if @_state == BEFORE_CDATA_5
      @_stateBeforeCdata5 c
    else if @_state == BEFORE_CDATA_6
      @_stateBeforeCdata6 c
    else if @_state == IN_CDATA
      @_stateInCdata c
    else if @_state == AFTER_CDATA_1
      @_stateAfterCdata1 c
    else if @_state == AFTER_CDATA_2
      @_stateAfterCdata2 c
    else if @_state == BEFORE_SPECIAL

      ###
      		* special tags
      ###

      @_stateBeforeSpecial c
    else if @_state == BEFORE_SPECIAL_END
      @_stateBeforeSpecialEnd c
    else if @_state == BEFORE_SCRIPT_1

      ###
      		* script
      ###

      @_stateBeforeScript1 c
    else if @_state == BEFORE_SCRIPT_2
      @_stateBeforeScript2 c
    else if @_state == BEFORE_SCRIPT_3
      @_stateBeforeScript3 c
    else if @_state == BEFORE_SCRIPT_4
      @_stateBeforeScript4 c
    else if @_state == BEFORE_SCRIPT_5
      @_stateBeforeScript5 c
    else if @_state == AFTER_SCRIPT_1
      @_stateAfterScript1 c
    else if @_state == AFTER_SCRIPT_2
      @_stateAfterScript2 c
    else if @_state == AFTER_SCRIPT_3
      @_stateAfterScript3 c
    else if @_state == AFTER_SCRIPT_4
      @_stateAfterScript4 c
    else if @_state == AFTER_SCRIPT_5
      @_stateAfterScript5 c
    else if @_state == BEFORE_STYLE_1

      ###
      		* style
      ###

      @_stateBeforeStyle1 c
    else if @_state == BEFORE_STYLE_2
      @_stateBeforeStyle2 c
    else if @_state == BEFORE_STYLE_3
      @_stateBeforeStyle3 c
    else if @_state == BEFORE_STYLE_4
      @_stateBeforeStyle4 c
    else if @_state == AFTER_STYLE_1
      @_stateAfterStyle1 c
    else if @_state == AFTER_STYLE_2
      @_stateAfterStyle2 c
    else if @_state == AFTER_STYLE_3
      @_stateAfterStyle3 c
    else if @_state == AFTER_STYLE_4
      @_stateAfterStyle4 c
    else if @_state == BEFORE_ENTITY

      ###
      		* entities
      ###

      @_stateBeforeEntity c
    else if @_state == BEFORE_NUMERIC_ENTITY
      @_stateBeforeNumericEntity c
    else if @_state == IN_NAMED_ENTITY
      @_stateInNamedEntity c
    else if @_state == IN_NUMERIC_ENTITY
      @_stateInNumericEntity c
    else if @_state == IN_HEX_ENTITY
      @_stateInHexEntity c
    else
      @_cbs.onerror Error('unknown _state'), @_state
    @_index++
  @_cleanup()
  return

Tokenizer::pause = ->
  @_running = false
  return

Tokenizer::resume = ->
  @_running = true
  if @_index < @_buffer.length
    @_parse()
  if @_ended
    @_finish()
  return

Tokenizer::end = (chunk) ->
  if @_ended
    @_cbs.onerror Error('.end() after done!')
  if chunk
    @write chunk
  @_ended = true
  if @_running
    @_finish()
  return

Tokenizer::_finish = ->
  #if there is remaining data, emit it in a reasonable way
  if @_sectionStart < @_index
    @_handleTrailingData()
  @_cbs.onend()
  return

Tokenizer::_handleTrailingData = ->
  data = @_buffer.substr(@_sectionStart)
  if @_state == IN_CDATA or @_state == AFTER_CDATA_1 or @_state == AFTER_CDATA_2
    @_cbs.oncdata data
  else if @_state == IN_COMMENT or @_state == AFTER_COMMENT_1 or @_state == AFTER_COMMENT_2
    @_cbs.oncomment data
  else if @_state == IN_NAMED_ENTITY and !@_xmlMode
    @_parseLegacyEntity()
    if @_sectionStart < @_index
      @_state = @_baseState
      @_handleTrailingData()
  else if @_state == IN_NUMERIC_ENTITY and !@_xmlMode
    @_decodeNumericEntity 2, 10
    if @_sectionStart < @_index
      @_state = @_baseState
      @_handleTrailingData()
  else if @_state == IN_HEX_ENTITY and !@_xmlMode
    @_decodeNumericEntity 3, 16
    if @_sectionStart < @_index
      @_state = @_baseState
      @_handleTrailingData()
  else if @_state != IN_TAG_NAME and @_state != BEFORE_ATTRIBUTE_NAME and @_state != BEFORE_ATTRIBUTE_VALUE and @_state != AFTER_ATTRIBUTE_NAME and @_state != IN_ATTRIBUTE_NAME and @_state != IN_ATTRIBUTE_VALUE_SQ and @_state != IN_ATTRIBUTE_VALUE_DQ and @_state != IN_ATTRIBUTE_VALUE_NQ and @_state != IN_CLOSING_TAG_NAME
    @_cbs.ontext data
  #else, ignore remaining data
  #TODO add a way to remove current tag
  return

Tokenizer::reset = ->
  Tokenizer.call this, {
    xmlMode: @_xmlMode
    decodeEntities: @_decodeEntities
  }, @_cbs
  return

Tokenizer::getAbsoluteIndex = ->
  @_bufferOffset + @_index

Tokenizer::_getSection = ->
  @_buffer.substring @_sectionStart, @_index

Tokenizer::_emitToken = (name) ->
  @_cbs[name] @_getSection()
  @_sectionStart = -1
  return

Tokenizer::_emitPartial = (value) ->
  if @_baseState != TEXT
    @_cbs.onattribdata value
    #TODO implement the new event
  else
    @_cbs.ontext value
  return
