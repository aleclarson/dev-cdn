isWritable = require('is-stream').writable

class EventStream
  constructor: ->
    @streams = new Set
    @

  emit: (event, props) ->
    event = "event: #{event}\ndata: #{JSON.stringify props}\n\n"
    @streams.forEach (stream) -> stream.write event

  pipe: (stream) ->

    if !isWritable stream
      throw Error 'Cannot add non-writable stream'

    # This stream is a ServerResponse.
    if stream.socket

      # Prepare the headers.
      stream.set
        'Connection': 'keep-alive'
        'Content-Type': 'text/event-stream; charset=utf-8'
        'Transfer-Encoding': 'chunked'

      # Send the headers.
      stream.flushHeaders()

    @streams.add stream
    unpipe = => @unpipe stream
    stream.on 'close', unpipe
    stream.on 'finish', unpipe
    return stream

  unpipe: (stream) ->
    if arguments.length
      @streams.delete stream
    else
      @streams.forEach (stream) -> stream.end()
      @streams.clear()
    return this

module.exports = EventStream
