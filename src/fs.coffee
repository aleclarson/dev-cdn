sortObject = require 'sort-obj'
fs = require 'fsx'
os = require 'os'

fs = Object.create fs

# Use ~/.cara/ as the working directory
fs.rootDir = os.homedir() + '/.cara'
fs.writeDir fs.rootDir

# Cache assets in ~/.cara/buckets/
fs.bucketDir = fs.rootDir + '/buckets'
fs.writeDir fs.bucketDir

fs.readJson = (file) ->
  JSON.parse fs.readFile file

fs.writeJson = (file, json) ->
  fs.writeFile file, JSON.stringify sortObject(json), null, 2

module.exports = fs
