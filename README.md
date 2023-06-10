<h1 align="center">
  <img src="https://raw.githubusercontent.com/wout/lucky_vite/main/logo.svg" width="200px"/>
</h1>

# LuckyVite

A Crystal shard to seamlessly integrate [Vite](https://vitejs.dev/) into [Lucky Framework](https://luckyframework.org/).

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  lucky_vite:
    github: wout/lucky_vite
```

2. Run `shards install`

3. Run `yarn add -D vite vite-plugin-lucky` to install vite and the plugin for lucky

## Setup

First run `bin/lucky_vite --init` to generate a basic setup. It will create the following files:

- `config/lucky_vite.json`: the shared config for Lucky and Vite
- `vite.config.js`: the Vite config loading `vite-plugin-lucky`
- `src/js/entry/main.js`: the first entry point with a basic setup
- `src/css/main.css`: an empty stylesheet which is referenced by `main.js`

You'll also need to replace the `Lucky::AssetHelpers.load_manifest` line in `src/app.cr` with:

```crystal
LuckyVite::AssetHelpers.load_manifest("public/assets/manifest.json")
```

## Configuration

Lucky and Vite share some information which is managed through the `config/lucky_vite.json` file. It comes with the following defaults:

```json
{
  "aliases": {
    "@css": "src/css",
    "@js": "src/js",
    "@images": "src/images",
    "@fonts": "src/fonts"
  },
  "outDir": "public/assets",
  "entry": "entry",
  "host": "127.0.0.1",
  "port": 3010,
  "root": "src/js"
}
```

Here's a bit more info about the available properties:

- **`outDir`** (_`string`_): the target dir for vite; this will be cleared on every run
- **`root`** (_`string`_): 
- **`entry`** (_`string`_): this is where vite looks for entry scripts (e.g. `src/js/entry`)
- **`https`** (_`boolean`_): uses `https:` for the vite server if set to `true`
- **`host`** (_`string | boolean`_): the host name where the vite server will be listening; if set to `true`, it will listen on `0.0.0.0` (all addresses)
- **`port`** (_`string | number`_): the port to listen on
- **`origin`** (_`string`_): use the full uri; alternative to using `https`, `host` and `port`
- **`aliases`** (_`object`_): helps to reference files (e.g. `@css/main.css` instead of `../css/main.css`)

**Note**: not all vite's configuration options are recognised here. Please open an issue or a PR if you are missing some. Alternatively, you can add them manually in the `vite.config.js`.

## Usage

```crystal
# in src/shards.cr
require "lucky_vite"
```

In your in the head of your page:

```crystal
# src/components/shared/layout_head.cr
vite_entry_tags "main.js"
```

This macro does a bunch of things. In development, it loads `@vite/client` and the given entry script. Vite will dynamically load any stylesheets imported in the entry script. In production, it will load the static versions from the manifest and create individual tags for all of them. With this macro, the whole frontend is served.

As a second argument, it accepts a named tuple for any attributes you'd want on the generated tags:

```crystal
vite_entry_tags "main.js", {data_turbo_track: "reload"}
```

If you want more control over the individual tags, we've got you covered:

```crystal
vite_client_tag
vite_js_link "main.js", {async: true}
vite_css_link "main.css"
```

The three individual methods above do the exact same thing as `vite_entry_tags`. Note that `vite_css_link` will not output anything in development.

If you need even more control over the generated tags, you can use the `vite_asset` macro in combination with Lucky's `js_link` and `css_link` methods:

```crystal
css_link vite_asset("main.css")
```

The `vite_asset` macro works exactly the same as Lucky's `asset` macro. Its `dynamic_asset` counterpart is also available:

```crystal
css_link dynamic_vite_asset("main.css")
```

Finally, if you're using React with the `@vitejs/plugin-react` plugin, you need to add the `vite_react_refresh_tag` method before any other asset tags to inject the refresh runtime served by Vite:

```crystal
vite_react_refresh_tag
vite_client_tag
# ...
```

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
