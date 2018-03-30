# cara-cdn v0.0.1 

A development server for bundles and static assets.

## project.js

The `project.js` module must exist in any roots you pass to `cdn.add()`.
This module describes the project to the server. The server loads the
module with `require` when `cdn.add()` is called.

Use the `.coffee` extension if you prefer CoffeeScript.

### `Project` class

The `project` variable exists in the scope of your project.
It provides methods for configuring the project's assets.

- [init(opts)]() General project configuration
- [bundle(name, opts)]() Describe a bundle
- [bucket(opts)]() Describe a bucket
- [match(path)]() Create an asset stream
- [watch(path)]() Watch files for changes

#### `init(opts)`

The following options are supported:

- `exts: string[]`

The `exts` array is a set of file extensions used when
crawling the project. You won't be able to reference
files in your bundle(s) unless their file extension
exists in this set. You don't need to specify the
extensions that exist in the names you pass to
the `bundle` method!

#### `bundle(name, opts)`

The `name` string may be a regular expression, except
the pattern should work with [glob-regex][1]. The file
extension will be parsed and added to the project's
extension set, which is used when crawling the project
for files.

The `opts` object is *optional*, and its properties vary
depending on the type of bundle. For example, you may specify
a `globals` property for `.js` bundles.

Most bundle types support a `main` property that tells the
bundler where the entry module is. And if the bundle name
uses regex parens (eg: `(a|b).css`), you can set `main`
to `./styles/$1` and `$1` will be replaced with either
`a` or `b` depending on what's being requested.

More information on available options can be found
in the [cara][2] documentation.

[1]: https://npmjs.org/package/glob-regex
[2]: https://github.com/aleclarson/cara

#### `match(path)`

The `path` string may be a glob or an array of globs.
Passing a function works just like `[].filter`.

Returns an `AssetStream` object.

### `AssetStream` class

A stream of asset filenames.

- [read()]() Read each asset and emit their contents
- [map(fn)]() Transform each asset or its contents
- [filter(fn)]() Ignore assets by returning falsy
- [concat()]() Combine the assets into an array
- [save()]() Save each asset in its bucket

Every method returns the same `AssetStream`.

#### `read()`

The `read` method reads each asset into a buffer.

Pass a string to set the encoding if you prefer
the assets to be read as a string.

Pass a function which takes a `Readable` stream
if you want to

```js
// Convert filenames into content buffers.
assets.read()

// Convert filenames into content strings.
assets.read('utf8')

// Do something with each file stream.
assets.read('utf8', (file) => {
  console.log('file.name =>', file.name)
  console.log('file.path =>', file.path)
  return file.pipe(gzip())
})
```

#### `map(fn)`

This method can transform asset filenames
or even content buffers.

#### `filter(fn)`

This method removes assets from the stream
if the filter function returns falsy.

#### `concat()`

Merge all matched assets into a single buffer.

Pass a string to set the encoding if you prefer
the result as a string.

#### `save()`

Save each transformed asset into its bucket.

Saving prevents each original asset from being cached
in the same bucket.

