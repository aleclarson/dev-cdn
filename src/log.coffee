huey = require 'huey'
noop = require 'noop'

log = (...args) ->
  log._log args.join ' '

log.set = (log) ->
  @_log = log or noop
  huey.log this, !!log and !process.env.NO_COLOR
  return

log.verbose = !!process.env.VERBOSE

module.exports = log
