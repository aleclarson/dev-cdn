Bucket = require './Bucket'
huey = require 'huey'
path = require 'path'
app = require './app'
log = require './log'
fs = require './fs'
vm = require 'vm'

# Projects describe their assets with this class.
class Project
  constructor: (root) ->
    @root = root
    @exts = []
    @bundles = Object.create null
    @

  init: (opts) ->
    if opts.exts
      @exts.push ...opts.exts
      return

  bundle: (name, opts = {}) ->
    if @bundles[name]
      throw Error "Bundle named '#{name}' already exists"

    @bundles[name] = opts
    @exts.push path.extname name
    return

  bucket: (opts) ->
    {name, root} = opts

    name ?= path.basename @root
    bucket = app.buckets[name]

    if typeof root is 'string'

      if !path.isAbsolute root
        root = path.resolve @root, root

      if !bucket
        bucket = new Bucket {name, root}
        app.buckets[name] = bucket

      else if bucket.root isnt root
        throw Error """
          Bucket name '#{name}' is already used by:
            #{bucket.root}
        """

    else if root?
      throw TypeError '`root` must be a string'

    else if !bucket
      throw Error 'Bucket does not exist: ' + name

    @buckets ?= new Set
    @buckets.add bucket
    return

  match: (glob) ->

    if typeof glob is 'string'
      # TODO: Support globbing.
      throw Error 'Not implemented yet'

    if typeof glob is 'function'
      # TODO: Filter functions
      throw Error 'Not implemented yet'

    if Array.isArray glob
      glob.forEach @match.bind this
      return

    throw TypeError 'Expected a string, function, or array'

  @load: (root) ->
    loadPath = root + '/project.js'
    unless fs.exists loadPath
      loadPath = root + '/project.coffee'
      if fs.exists loadPath
        coffee = true
      else return false

    load = fs.readFile loadPath
    if coffee
      try coffee = require 'coffeescript'
      catch err
        log.yellow 'warn:', """
          You must do #{huey.cyan 'npm install -g coffeescript'} \
          before any 'project.coffee' files can be loaded!
        """
        return false

      load = coffee.compile load,
        bare: true
        filename: loadPath
        sourceMap: false

    project = new Project root
    vm.runInNewContext load, {project},
      filename: path
      displayErrors: true
      timeout: 10000 # 10s

    return project

module.exports = Project

# Assets can be mutated with this class.
class AssetStream
  constructor: (stream) ->
    @_stream = stream
    @

  transform: (fn) ->
    throw Error 'Not implemented yet'

  filter: (fn) ->
    throw Error 'Not implemented yet'

  concat: ->
    throw Error 'Not implemented yet'

  toArray: ->
    throw Error 'Not implemented yet'
