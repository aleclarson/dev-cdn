// Generated by CoffeeScript 2.2.4
var fs, os, sortObject;

sortObject = require('sort-obj');

fs = require('fsx');

os = require('os');

fs = Object.create(fs);

// Use ~/.cara/ as the working directory
fs.rootDir = os.homedir() + '/.cara';

fs.writeDir(fs.rootDir);

// Cache assets in ~/.cara/buckets/
fs.bucketDir = fs.rootDir + '/buckets';

fs.writeDir(fs.bucketDir);

fs.readJson = function(file) {
  return JSON.parse(fs.readFile(file));
};

fs.writeJson = function(file, json) {
  return fs.writeFile(file, JSON.stringify(sortObject(json), null, 2));
};

module.exports = fs;

//# sourceMappingURL=fs.js.map