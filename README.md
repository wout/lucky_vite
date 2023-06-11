<h1 align="center">
  <img src="https://raw.githubusercontent.com/wout/lucky_vite/main/logo.svg" width="200px"/>

  <br>

  Lucky Vite
</h1>

A Crystal shard to seamlessly integrate [Vite](https://vitejs.dev/) with [Lucky Framework](https://luckyframework.org/).

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  lucky_vite:
    github: wout/lucky_vite
```

2. Run `shards install`

3. Run `yarn add -D vite vite-plugin-lucky` to install Vite and the plugin for Lucky

## Setup

There are a few things to set up and change to finalize the installation.

### 1. Generate files

Run `bin/lucky_vite --init` to create the following files:

- `config/lucky_vite.json`: the shared config for Lucky and Vite
- `vite.config.js`: the Vite config loading `vite-plugin-lucky`
- `src/js/entry/main.js`: the first entry point with a basic setup
- `src/css/main.css`: an empty stylesheet which is referenced by `main.js`

### 2. Load the Vite manifest

Replace the `Lucky::AssetHelpers.load_manifest` line in `src/app.cr` with:

```diff
-Lucky::AssetHelpers.load_manifest "public/mix-manifest.json"
+LuckyVite::AssetHelpers.load_manifest
```

### 3. Register the Vite processes

Update the `Procfile.dev` by removing the `assets` process and adding the two following ones:

```diff
system_check: script/system_check && sleep 100000
web: lucky watch --reload-browser
-assets: yarn watch
+vite_server: yarn vite
+vite_watcher: yarn watch
```

### 4. Register the Vite runners

Change the scripts section in `package.json` to use vite instead of laravel mix:

```diff
{
  // ...
  "scripts": {
-    "heroku-postbuild": "yarn prod",
-    "dev": "yarn run mix",
-    "watch": "yarn run mix watch",
-    "prod": "yarn run mix --production",
+    "heroku-postbuild": "yarn build",
+    "build": "yarn run vite build",
+    "watch": "yarn run vite build --watch"
  },
  // ...
}
```

## Usage

Start with including the shard in your app first:

```crystal
# in src/shards.cr
require "lucky_vite"
```

### Tags

This shard provides three levels of control over the individual Vite tags.

#### Hands-off

The `vite_entry_tags` macro method serves all your Vite needs, but it gives you the least amount of control over the individual tags that are generated:

```crystal
# src/components/shared/layout_head.cr
vite_entry_tags "main.js"
```

It does a bunch of things. In development, it loads `@vite/client` and the given entry script. Vite will dynamically load any stylesheets imported in the entry script.

In production, it will load the static versions from the manifest and create individual tags for all of them, including stylesheets. With this macro, the whole frontend is served.

It also accepts any attributes you'd want on all the generated tags:

```crystal
vite_entry_tags "main.js", data_turbo_track: "reload"
```

One downside is that the attributes will be applied to all generated tags, which you may not want in some cases.

#### A bit of control

If you need different attribtues on style tags than on script tags, you can use the following three methods:

```crystal
vite_client_tag
vite_js_link "main.js"
vite_css_link "main.css"
```

Together they do the exact same thing as `vite_entry_tags`.

**Note**: `vite_css_link` won't output anything in development as stylesheets are dynamically loaded by Vite.

#### Full control

If you need even more control over the generated tags, you can use the `vite_asset` macro in combination with Lucky's `js_link` and `css_link` methods:

```crystal
vite_client_tag
js_link vite_asset("main.js"), type: "module"
css_link vite_asset("main.css") unless LuckyEnv.development?
```

The example above does the exact same thing as `vite_entry_tags`.

### Using React

If you're using React with the `@vitejs/plugin-react` plugin, you need to add the `vite_react_refresh_tag` method before any other asset tags to inject the refresh runtime served by Vite:

```crystal
vite_react_refresh_tag
vite_client_tag
# ...
```

### Static assets

LuckyVite manages the asset pipeline, so Lucky's `asset` and `dynamic_asset` macros are no longer working as expected. Instead, you should use `vite_asset` and `dynamic_vite_asset`.

```crystal
img src: vite_asset("@images/logo.png")
```

**Note**: The asset helper uses Vite's aliases for easier referencings. Aliases can be configured in `config/lucky_vite.json`.

## Configuration

Lucky and Vite share some information which is managed through the `config/lucky_vite.json` file. It comes with the following defaults:

```json
{
  "aliases": [
    "css",
    "fonts",
    "images",
    "js"
  ],
  "outDir": "public/assets",
  "root": "src/js",
  "entry": "entry",
  "host": "127.0.0.1",
  "port": 3010
}
```

Here's a bit more info about the available properties:

- **`aliases`** (_`string[]`_): a list of directories for Vite to create aliases for (e.g. `@images` becomes `src/images`; defaults to ['js', 'css', 'images', 'fonts'])
- **`outDir`** (_`string`_): the target dir for Vite; this will be cleared on every run
- **`root`** (_`string`_): the javascript root (typically `src/js`)
- **`entry`** (_`string`_): this is where Vite looks for entry scripts (e.g. `src/js/entry`)
- **`https`** (_`boolean`_): uses `https:` for the Vite server if set to `true`
- **`host`** (_`string | boolean`_): the host name where the Vite server will be listening; if set to `true`, it will listen on `0.0.0.0` (all addresses)
- **`port`** (_`string | number`_): the port to listen on
- **`origin`** (_`string`_): use the full uri; alternative to using `https`, `host` and `port`

**Note**: not all Vite's configuration options are recognised here. Please open an issue or a PR if you are missing some. Alternatively, you can also add them directly in `vite.config.js`.

## Development

Make sure you have [Guardian.cr](https://github.com/f/guardian) installed. Then run:

```bash
$ guardian
```

This will automatically:
- run ameba for src and spec files
- run the relevant spec for any file in src
- run spec file whenever they are saved

## Contributing

We use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) for our commit messages, so please adhere to that pattern.

1. Fork it (<https://github.com/wout/lucky_vite/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'feat: new feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Wout](https://github.com/wout) - creator and maintainer
