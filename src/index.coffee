watcher = require './watcher'
app = require './app'
api = require './api'
log = require './log'

cdn = exports

cdn.run = (opts) ->
  if app.server
    throw Error 'Already started'

  log.set opts.log if opts.log?
  app.start().pipe(api).ready ->
    log.pale_green 'Server ready!'
    watcher.start()

cdn.stop = ->
  if app.server
    app.stop()
    watcher.stop()

cdn.add = (root) ->
  project = app.add root
  watcher.watch project.root

cdn.remove = app.remove.bind app
