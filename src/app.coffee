globRegex = require 'glob-regex'
{Bundler} = require 'cara'
slush = require 'slush'
steal = require 'steal'
huey = require 'huey'
noop = require 'noop'
path = require 'path'
log = require './log'
fs = require './fs'
os = require 'os'

SOCK_PATH = os.homedir() + '/.cara/cdn.sock'

class App

  start: ->
    @server = slush {sock: SOCK_PATH}
    @bundler = new Bundler
    @buckets = {}
    @projects = {}

    @bundler.on 'warn', (msg) ->
      log.yellow 'warn:', msg

    @bundler.on 'error', onError
    @server.on 'error', onError
    return @server

  stop: ->
    if log.verbose
      log.pale_pink 'Closing asset server...'
    fs.removeFile SOCK_PATH, false
    @server.close()
    @server = null
    @bundler = null
    @buckets = null
    @projects = null
    return

  read: (req, res) ->
    return project.read req, res if req.project
    for root, project of req.bucket.projects
      val = project.read req, res
      return val if val isnt false

  add: (root) ->
    if @projects.hasOwnProperty root
      throw Error 'Already loaded: ' + root

    if log.verbose
      log.pale_yellow 'Loading project:', root

    # TODO: Watch project file for changes.
    config = Project.load root
    project = @bundler.project
      root: config.root
      fileTypes: config.exts

    # Remember which buckets we are using.
    project.buckets = config.buckets
    config.buckets.forEach (bucket) ->
      bucket.projects[root] = project

    # Populate the bundler with files.
    crawlProject project

    # Setup the bundle readers.
    bundleNames = Object.keys config.bundles
    bundles = bundleNames.map (bundleName) ->
      opts = config.bundles[bundleName]
      opts.onStop ?= noop

      bundleName = globRegex bundleName
      bundleMain = steal opts, 'main'

      return (req, res) ->
        unless match = bundleName.exec req.file
          return false

        project.bundle
          dev: /^(1||true)$/.test req.query.dev
          main: fillRefs bundleMain, match
          platform: req.query.platform or 'web'

        .then (bundle) ->
          started = Date.now()
          cached = bundle.isCached

          code = await bundle.read opts
          if bundle.error
            res.status 400
            res.send bundle.error
            return true

          if code and !cached
            elapsed = huey.cyan getElapsed started
            mainPath = huey.pale_green '~/' + bundle._main.name
            log "📦 Bundled #{mainPath} in #{elapsed}"
          return code

    project.read = (req, res) ->
      try for read in bundles
        val = await read req, res
        return val if val isnt false
      catch err
        if err.code is 'NO_MAIN_MODULE'
          res.status 400
          res.send
            error: err.message
            code: err.code
          return true
        throw err

    @projects[root] = project
    return project

  # TODO: Properly unload the compiler for each bundle.
  remove: (root) ->
    if @projects.hasOwnProperty root
      if log.verbose
        log.pale_pink 'Unloading project:', root

      # Remove unused buckets.
      {buckets} = @projects[root]
      buckets?.forEach (bucket) =>
        if bucket.drop root
          delete @buckets[bucket.name]

      # Remove the project.
      delete @projects[root]

module.exports = new App

# app -> Project -> app
Project = require './Project'

# Replaces '$1' with `arr[1]` etc.
fillRefs = (str, arr) ->
  if str
  then str.replace /\$[0-9]+/g, (str) -> arr[str.slice 1]
  else ''

getElapsed = (started) ->
  elapsed = Date.now() - started
  if elapsed < 1000 then elapsed + 'ms'
  else (elapsed / 1000).toFixed(3) + 's'

# TODO: Use watchman for crawling.
crawlProject = (project) ->
  started = Date.now()
  project.crawl()
  elapsed = huey.cyan getElapsed started
  name = huey.pale_green project.root.name
  log "✨ Crawled #{name} in #{elapsed}"
  return

onError = (err) ->
  if process.env.VERBOSE
  then log err.stack
  else log.red err.name + ':', err.message
