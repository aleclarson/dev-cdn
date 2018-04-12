// Generated by CoffeeScript 2.2.4
var huey, log, noop;

huey = require('huey');

noop = require('noop');

log = function(...args) {
  return log._log(args.join(' '));
};

log.set = function(log) {
  this._log = log || noop;
  huey.log(this, !!log && !process.env.NO_COLOR);
};

log.verbose = !!process.env.VERBOSE;

module.exports = log;

//# sourceMappingURL=log.js.map
