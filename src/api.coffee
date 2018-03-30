EventStream = require './EventStream'
mimeTypes = require 'mime-types'
Router = require 'yiss'
app = require './app'
fs = require './fs'

api = new Router

api.listen (req, res) ->

  if name = req.get 'x-bucket'
    unless req.bucket = app.buckets[name]
      res.status 404
      return error: 'Unknown bucket: ' + name

  else if name = req.get 'x-project'
    unless req.project = app.projects[name]
      res.status 404
      return error: 'Unknown project: ' + name

  else
    res.status 400
    return error: "Missing both 'X-Bucket' and 'X-Project' headers"

api.GET '/b/assets.json', (req, res) ->
  if req.accepts 'text/event-stream'

    if req.file isnt 'assets.json'
      res.set 'Error', 'Unknown event stream'
      return 404

    if req.bucket
      req.bucket.events.pipe res
      return true
    return 404

api.PATCH '/b/assets.json', (req) ->
  if req.bucket
    req.bucket.patch await req.json()
    return true
  return 404

# TODO: Support source maps.
api.GET '/b/**/*.map', -> '{}'

api.GET '/b/:file(.+)', (req, res) ->
  req.file = req.params.file
  file = req.bucket?.get req.file
  file ?= await app.read req, res
  return if res.headersSent
  return 404 unless file

  contentLength =
    if typeof file is 'string'
    then Buffer.byteLength file
    else fs.stat(file.path).size

  res.set
    'Content-Type': mimeTypes.lookup(req.file) or 'application/octet-stream'
    'Content-Length': contentLength
    'Cache-Control': 'no-store'

  if typeof file is 'string'
  then res.send file
  else file.pipe res
  return true

module.exports = api.bind()
