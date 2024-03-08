htmlparser2 = require('..')
assert = require('assert')
describe 'WritableStream', ->
  it 'should decode fragmented unicode characters', ->
    processed = false
    stream = new (htmlparser2.WritableStream)(ontext: (text) ->
      assert.equal text, '€'
      processed = true
      return
)
    stream.write new Buffer([
      0xe2
      0x82
    ])
    stream.write new Buffer([ 0xac ])
    stream.end()
    assert processed
    return
  return
