htmlparser2 = require('..')
assert = require('assert')
describe 'API', ->
  it 'should load all modules', ->
    Stream = require('../lib/Stream.js')
    assert.strictEqual htmlparser2.Stream, Stream, 'should load module'
    assert.strictEqual htmlparser2.Stream, Stream, 'should load it again (cache)'
    ProxyHandler = require('../lib/ProxyHandler.js')
    assert.strictEqual htmlparser2.ProxyHandler, ProxyHandler, 'should load module'
    assert.strictEqual htmlparser2.ProxyHandler, ProxyHandler, 'should load it again (cache)'
    return
  it 'should work without callbacks', ->
    p = new (htmlparser2.Parser)(null,
      xmlMode: true
      lowerCaseAttributeNames: true)
    p.end '<a foo><bar></a><!-- --><![CDATA[]]]><?foo?><!bar><boo/>boohay'
    p.write 'foo'
    #check for an error
    p.end()
    err = false

    p._cbs.onerror = ->
      err = true
      return

    p.write 'foo'
    assert err
    err = false
    p.end()
    assert err
    p.reset()
    #remove method

    p._cbs.onopentag = ->

    p.write '<a foo'
    p._cbs.onopentag = null
    p.write '>'
    #pause/resume
    processed = false

    p._cbs.ontext = (t) ->
      assert.equal t, 'foo'
      processed = true
      return

    p.pause()
    p.write 'foo'
    assert !processed
    p.resume()
    assert processed
    processed = false
    p.pause()
    assert !processed
    p.resume()
    assert !processed
    p.pause()
    p.end 'foo'
    assert !processed
    p.resume()
    assert processed
    return
  it 'should update the position', ->
    p = new (htmlparser2.Parser)(null)
    p.write 'foo'
    assert.equal p.startIndex, 0
    assert.equal p.endIndex, 2
    p.write '<bar>'
    assert.equal p.startIndex, 3
    assert.equal p.endIndex, 7
    return
  it 'should update the position when a single tag is spread across multiple chunks', ->
    p = new (htmlparser2.Parser)(null)
    p.write '<div '
    p.write 'foo=bar>'
    assert.equal p.startIndex, 0
    assert.equal p.endIndex, 12
    return
  it 'should support custom tokenizer', ->

    CustomTokenizer = (options, cbs) ->
      htmlparser2.Tokenizer.call this, options, cbs
      this

    CustomTokenizer.prototype = Object.create(htmlparser2.Tokenizer.prototype)
    CustomTokenizer::constructor = CustomTokenizer
    p = new (htmlparser2.Parser)({ onparserinit: (parser) ->
      assert parser._tokenizer instanceof CustomTokenizer
      return
 }, Tokenizer: CustomTokenizer)
    p.done()
    return
  return
