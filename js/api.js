// Generated by CoffeeScript 2.2.4
var EventStream, Router, api, app, fs, mimeTypes;

EventStream = require('./EventStream');

mimeTypes = require('mime-types');

Router = require('yiss');

app = require('./app');

fs = require('./fs');

api = new Router;

api.listen(function(req, res) {
  var name;
  if (name = req.get('x-bucket')) {
    if (!(req.bucket = app.buckets[name])) {
      res.status(404);
      return {
        error: 'Unknown bucket: ' + name
      };
    }
  } else if (name = req.get('x-project')) {
    if (!(req.project = app.projects[name])) {
      res.status(404);
      return {
        error: 'Unknown project: ' + name
      };
    }
  } else {
    res.status(400);
    return {
      error: "Missing both 'X-Bucket' and 'X-Project' headers"
    };
  }
});

api.GET('/b/assets.json', function(req, res) {
  if (req.accepts('text/event-stream')) {
    if (req.file !== 'assets.json') {
      res.set('Error', 'Unknown event stream');
      return 404;
    }
    if (req.bucket) {
      req.bucket.events.pipe(res);
      return true;
    }
    return 404;
  }
});

api.PATCH('/b/assets.json', async function(req) {
  if (req.bucket) {
    req.bucket.patch((await req.json()));
    return true;
  }
  return 404;
});

// TODO: Support source maps.
api.GET('/b/**/*.map', function() {
  return '{}';
});

api.GET('/b/:file(.+)', async function(req, res) {
  var contentLength, file, ref;
  req.file = req.params.file;
  file = (ref = req.bucket) != null ? ref.get(req.file) : void 0;
  if (file == null) {
    file = (await app.read(req, res));
  }
  if (res.headersSent) {
    return;
  }
  if (!file) {
    return 404;
  }
  contentLength = typeof file === 'string' ? Buffer.byteLength(file) : fs.stat(file.path).size;
  res.set({
    'Content-Type': mimeTypes.lookup(req.file) || 'application/octet-stream',
    'Content-Length': contentLength,
    'Cache-Control': 'no-store'
  });
  res.flushHeaders();
  if (typeof file === 'string') {
    res.send(file);
  } else {
    file.pipe(res);
  }
  return true;
});

module.exports = api.bind();

//# sourceMappingURL=api.js.map
