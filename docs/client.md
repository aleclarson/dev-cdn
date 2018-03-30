# API guide

1. Connect to `~/.cara/cdn.sock`
2. Specify `X-Bucket` header for each request

### `GET /b/[asset]`

Fetch the raw data of an asset.

### `GET /b/assets.json`

Fetch the assets manifest, which is a map where the keys are asset IDs
and the values are asset filenames (which include content hashes).

Assets whose IDs are identical to their filenames (unhashed assets)
have their values set to `true`.

Set your `Accept` header to `text/event-stream` to listen for
updates to the manifest.

Each line in the event stream is a JSON string:

```json
{"event":"change","name":"foo.svg","value":"foo.1ae8crf21m.svg"}
{"event":"add","name":"a/b/c.txt","value":true}
{"event":"delete","name":"x/y/z.json"}
```

### `PATCH /b/assets.json`

Patch the assets manifest.

