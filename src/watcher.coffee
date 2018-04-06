path = require 'path'
app = require './app'
log = require './log'
wch = require 'wch'
fs = require './fs'

# TODO: Invalidate package files when the package becomes unused

started = false
streams = new Map

exports.start = ->
  if !started
    started = true

    {bundler} = app
    bundler.on 'package:used', @watch
    bundler.on 'package:unused', @unwatch
    return

exports.watch = (pack) ->
  if !streams.has pack
    streams.set pack, watchPackage pack

exports.unwatch = (pack) ->
  if stream = streams.get pack
    streams.delete pack
    stream.destroy()

exports.stop = ->
  if log.verbose
    log.pale_pink 'Closing watch streams...'
  started = false
  streams.forEach (s) -> s.destroy()
  return

#
# Helpers
#

fields = ['name', 'type', 'new', 'exists']
ignored = [
  '**/node_modules/**' # dependencies
  '.*.sw[a-z]', '*~'   # vim temporary files
  '.DS_Store'          # macOS Finder metadata
]

# TODO: Update `package.dirs` when directories are added/removed
# TODO: Clear module resolutions for removed dependencies
watchPackage = (pack) ->
  root = fs.readLinks pack.path
  log.pale_green 'Watching package:', root
  wch.stream root, {fields, exclude: ignored}
  .on 'data', (file) ->

    if file.name is 'package.json'
      return pack._readMeta()

    if file.type is 'd'
      return

    {bundler} = pack
    if file.new
      ext = path.extname file.name
      return bundler.addFile file.path, ext, pack

    if file.exists
      bundler.reloadFile file.path
    else
      bundler.deleteFile file.path
    return

#   const bundles = project
#     .filterBundles(bundle => bundle.hasModule(file))
#
#   if (patch.event == 'change') {
#     bundles.forEach(bundle => {
#       bundle.reloadModule(patch.file)
#     })
#   } else if (patch.event == 'unlink') {
#     bundles.forEach(bundle => {
#       bundle.deleteModule(patch.file)
#     })
#   } else {
#     const error = 'Expected `body.event` to equal "change" or "unlink"'
#     return {status: 400, error}
#   }
#
#   return {status: 200}
# }
