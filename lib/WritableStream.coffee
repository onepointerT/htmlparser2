Stream = (cbs, options) ->
  parser = @_parser = new Parser(cbs, options)
  decoder = @_decoder = new StringDecoder
  WritableStream.call this, decodeStrings: false
  @once 'finish', ->
    parser.end decoder.end()
    return
  return

module.exports = Stream
Parser = require('./Parser.js')
WritableStream = require('readable-stream').Writable
StringDecoder = require('string_decoder').StringDecoder
Buffer = require('buffer').Buffer
require('inherits') Stream, WritableStream

WritableStream::_write = (chunk, encoding, cb) ->
  if chunk instanceof Buffer
    chunk = @_decoder.write(chunk)
  @_parser.write chunk
  cb()
  return
