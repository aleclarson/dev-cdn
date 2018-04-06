EventStream = require './EventStream'
hasKeys = require 'hasKeys'
crypto = require 'crypto'
huey = require 'huey'
noop = require 'noop'
path = require 'path'
app = require './app'
log = require './log'
wch = require 'wch'
fs = require './fs'

setProto = Object.setPrototypeOf
defaultIgnore = [
  '.*.sw[a-z]', '*~' # vim temporary files
  '.DS_Store'        # macOS Finder metadata
]

# Buckets are local caches for project assets.
class Bucket
  constructor: (opts) ->
    @name = opts.name
    @root = opts.root
    @ignore = opts.ignore or defaultIgnore
    @assets = @_loadAssets()
    @events = new EventStream
    @projects = Object.create null
    @

  has: (name) ->
    return @assets[name]?

  get: (name) ->
    if value = @assets[name]
      value = name if value is true
      return fs.read @_dest value

  patch: (values) ->
    for name, value of values

      if value is null
        @delete name
        continue

      prev = @assets[name]
      @assets[name] = value

      if prev
        prev = name if prev is true
        prev = @_dest prev

        value = name if value is true
        fs.rename prev, @_dest value

      event = if prev then 'change' else 'add'
      @events.emit event, {name, value}

    @save()
    return

  put: (name) ->
    src = path.join @root, name
    file = fs.readFile src, null

    value = @assets[name]
    exists = value?

    # Assets set to true have no content hash.
    if value is true
      dest = name
    else
      ext = path.extname name
      dest = name.slice(0, 1 - ext.length) + sha256(file, 10) + ext
      return if dest is value
      @assets[name] = value = dest
      @save()

    dest = @_dest dest
    fs.writeDir path.dirname dest if !exists
    fs.writeFile dest, file

    event = if exists then 'change' else 'add'
    unless @loading
      log.pale_green "Asset #{past event}:", huey.gray("/b/#{@name}/") + name
    @events.emit event, {name, value}
    return

  delete: (name) ->
    if dest = @assets[name]
      delete @assets[name]
      @save()

      dest = name if dest is true
      dest = @_dest dest

      # Jump to the bucket directory.
      cwd = process.cwd()
      process.chdir fs.bucketDir

      # Remove the file, and its directory (if empty)
      fs.removeFile dest
      try fs.removeDir path.dirname(dest), false

      # Return to the working directory.
      process.chdir cwd

      unless @loading
        log.pale_pink 'Asset deleted:', huey.gray("/b/#{@name}/") + name
      @events.emit 'delete', {name}
      return

  query: (opts = {}) ->
    opts.exclude = @ignore
    wch.query @root, opts

  save: ->
    fs.writeJson @_dest('assets.json'), @assets

  drop: (root) ->

    if arguments.length
      delete @projects[root]
      return false if hasKeys @projects
    else @projects = Object.create null

    @events.unpipe()
    @watcher.destroy()

    # Jump to the bucket directory.
    cwd = process.cwd()
    process.chdir fs.bucketDir
    fs.removeDir @_dest()

    # Return to the working directory.
    process.chdir cwd
    return true

  _dest: (name = '') ->
    path.join fs.bucketDir, @name, name

  _resolve: (...args) ->
    name = path.relative @root, path.join ...args
    if name[0] isnt '.' then name else null

  _loadAssets: ->
    bucketPath = @_dest()
    if fs.isDir bucketPath
      log.pale_yellow 'Loading bucket:', @name
    else
      log.pale_green 'New bucket:', @name, '->', @root
      fs.writeDir bucketPath

    jsonPath = @_dest 'assets.json'
    if assets = loadAssets jsonPath
      query = @query
        since: fs.stat(jsonPath).mtime
    else
      assets = Object.create null
      query = @query()

    query.then (files) =>
      @save = noop
      @loading = true

      {root} = files
      files.forEach (file) =>
        name = @_resolve root, file.name
        if file.exists
        then @put name
        else @delete name

      @loading = false

      # Save even if no changes were made.
      delete @save
      @save()

      @watcher = wch.stream root
      .on 'data', (file) =>
        if name = @_resolve file.path
          if file.exists then @put name else @delete name

    .catch (err) ->
      console.error err.stack

    return assets

module.exports = Bucket

past = (str) ->
  str.replace /e?$/, 'ed'

loadAssets = (jsonPath) ->
  if fs.isFile jsonPath
    assets = fs.readJson jsonPath
    setProto assets, null
    return assets

sha256 = (buffer, length) ->

  hash = crypto
    .createHash 'sha256'
    .update buffer
    .digest 'hex'

  if typeof length is 'number'
  then hash.slice 0, length
  else hash
