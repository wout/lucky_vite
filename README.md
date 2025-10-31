<h1 align="center">
  <img src="https://raw.githubusercontent.com/wout/lucky_vite/main/logo.svg" width="200px"/>

  <br>

Lucky Vite

</h1>

<h3 align="center">
  A Crystal shard to seamlessly integrate <a href="https://vitejs.dev/" tagret="_blank">Vite</a> with <a href="https://luckyframework.org/" tagret="_blank">Lucky Framework</a>.
</h3>

<p align="center">
  This shard follows Vite's instructions on how to <a href="https://vitejs.dev/guide/backend-integration.html#backend-integration" target="_blank">use Vite with a backend framework</a>
</p>

<div align="center">
  <img src="https://img.shields.io/github/license/wout/lucky_vite" title="Github"/>
  <img src="https://img.shields.io/github/v/tag/wout/lucky_vite" title="GitHub tag (latest SemVer)"/>
  <img src="https://img.shields.io/github/actions/workflow/status/wout/lucky_vite/ci.yml?branch=main" title="GitHub Workflow Status"/>
</div>

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  lucky_vite:
    github: wout/lucky_vite
```

2. Run `shards install`

3. Run `yarn add -D vite vite-plugin-lucky` to install Vite and the plugin for Lucky

> [!Note]
> Look at [vite-plugin-lucky](https://github.com/wout/vite-plugin-lucky) for more info about the plugin.

## Setup

There are a few things to set up and change to finalize the installation.

### 1. Generate files

Run **`bin/lucky_vite init`** to create the following files:

- `config/lucky_vite.json`: the shared config for Lucky and Vite
- `vite.config.js`: the Vite config loading `vite-plugin-lucky`
- `src/js/entry/main.js`: the first entry point with a basic setup
- `src/css/main.css`: an empty stylesheet which is referenced by `main.js`

> [!Note]
> The initializer accepts a name option for the entry script: `bin/lucky_vite init --name=app`.

### 2. Load the Vite manifest

Replace the `Lucky::AssetHelpers.load_manifest` line in `src/app.cr` with:

```diff
-Lucky::AssetHelpers.load_manifest
+LuckyVite::AssetHelpers.load_manifest
```

> [!Note]
> The `load_manifest` macro optionally takes a path to the `lucky_vite.json` config.

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

### 5. Add manifest setup

In `script/setup.cr`, find the "Compiling assets" step and change the command:

```diff
# ...
notice "Compiling assets"
- run_command "yarn", "dev"
+ run_command "yarn", "run", "vite", "build"
# ...
```

### Further steps

- if you use the CI workflow for Github Actions, you need to change `yarn prod` into `yarn build` in `ci.yml`
- you may want to exclude `public/.vite`, `public/css`, `public/fonts`, `public/images`, and `public/js` from the repo
- all the `laravel-mix` dependencies can be removed from from `package.json`
- `webpack.mix.js` can be removed

## Usage

Start with including the shard in your app first:

```crystal
# in src/shards.cr
require "lucky_vite"
```

### Tags

This shard provides three levels of control over the individual Vite tags.

**Important**: All `vite_*` tags should be placed at the absolute bottom of your <head> element. HMR functionality will remove all tags between the entry point tag and the end of head.

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
vite_js_link "main.js", defer: true
vite_css_links "main.js"
```

Together they do the exact same thing as `vite_entry_tags`.

> [!Note]
> The `vite_css_links` macro takes the main JS entry point as an argument, because that's where the CSS is imported. This macro will only generate output in production.

#### Full control

If you need even more control over the generated tags, you can use the `asset` macro in combination with Lucky's `js_link` and `css_link` methods:

```crystal
vite_client_tag
js_link asset("main.js"), type: "module"
vite_css_links "main.js"
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

LuckyVite manages the asset pipeline by overwriting Lucky's `asset` and `dynamic_asset` macros.

```crystal
img src: asset("@images/logo.png")
```

> [!Note]
> The asset helper uses Vite's aliases for easier referencing. Aliases can be configured in `config/lucky_vite.json`.

## Configuration

Lucky and Vite share some information which is managed through the `config/lucky_vite.json` file. It comes with the following defaults:

```json
{
  "aliases": ["css", "fonts", "images", "js"],
  "outDir": "public",
  "root": "src/js",
  "entry": "entry",
  "host": "127.0.0.1",
  "port": 3010
}
```

Here's a bit more info about the available properties:

- **`aliases`** (_`string[]`_): a list of directories for Vite to create aliases
  - _default_: `["js", "css", "images", "fonts"]`)
  - _example_: `@images` becomes `src/images`
- **`outDir`** (_`string`_): the target dir for Vite
  - _default_: `"public"`
  - _note_: this will be cleared on every run
- **`root`** (_`string`_): the javascript root
  - _default_: `"src/js"`
- **`entry`** (_`string`_): this is where Vite looks for entry scripts
  - _default_: `"entry"`
- **`https`** (_`boolean`_): uses `https:` for the Vite server if set to `true`
  - _default_: `false`
- **`host`** (_`string | boolean`_): host name for the Vite server
  - _default_: `"127.0.0.1"`
  - _note_: if set to `true`, it will listen on `0.0.0.0` (all addresses)
- **`port`** (_`string | number`_): port for the Vite server
  - _default_: `3010`
- **`origin`** (_`string`_): alternative to using `https`, `host` and `port`
  - _example_: `"http://localhost:3210"`

> [!Note]
> Not all Vite's configuration options are recognised here as this file covers that's shared between Vite and Lucky. You can add other Vite-specific configuration options directly in `vite.config.js`.

## Documentation

- [API (main)](https://wout.github.io/lucky_vite/)

## Contributing

We use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) for our commit messages, so please adhere to that pattern.

1. Fork it (<https://github.com/wout/lucky_vite/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'feat: new feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Wout](https://github.com/wout) - creator and maintainer
