crystal_doc_search_index_callback({"repository_name":"lucky_vite","body":"<h1 align=\"center\">\n  <img src=\"https://raw.githubusercontent.com/wout/lucky_vite/main/logo.svg\" width=\"200px\"/>\n\n  <br>\n\n  Lucky Vite\n</h1>\n\nA Crystal shard to seamlessly integrate [Vite](https://vitejs.dev/) with [Lucky Framework](https://luckyframework.org/).\n\n![GitHub](https://img.shields.io/github/license/wout/lucky_vite)\n![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/wout/lucky_vite)\n![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/wout/lucky_vite/ci.yml?branch=main)\n\n## Installation\n\n1. Add the dependency to your `shard.yml`:\n\n```yaml\ndependencies:\n  lucky_vite:\n    github: wout/lucky_vite\n```\n\n2. Run `shards install`\n\n3. Run `yarn add -D vite vite-plugin-lucky` to install Vite and the plugin for Lucky\n\n**Node**: Look at [vite-plugin-lucky](https://github.com/wout/vite-plugin-lucky) for more info about the plugin.\n\n## Setup\n\nThere are a few things to set up and change to finalize the installation.\n\n### 1. Generate files\n\nRun `bin/lucky_vite --init` to create the following files:\n\n- `config/lucky_vite.json`: the shared config for Lucky and Vite\n- `vite.config.js`: the Vite config loading `vite-plugin-lucky`\n- `src/js/entry/main.js`: the first entry point with a basic setup\n- `src/css/main.css`: an empty stylesheet which is referenced by `main.js`\n\n### 2. Load the Vite manifest\n\nReplace the `Lucky::AssetHelpers.load_manifest` line in `src/app.cr` with:\n\n```diff\n-Lucky::AssetHelpers.load_manifest \"public/mix-manifest.json\"\n+LuckyVite::AssetHelpers.load_manifest\n```\n\n**Node**: The Vite manifest path does not need to be passed here. It's loaded from the configured `outDir` by LuckyVite. Instead, a custom location to the `lucky_vite.json` config can be passed.\n\n### 3. Register the Vite processes\n\nUpdate the `Procfile.dev` by removing the `assets` process and adding the two following ones:\n\n```diff\nsystem_check: script/system_check && sleep 100000\nweb: lucky watch --reload-browser\n-assets: yarn watch\n+vite_server: yarn vite\n+vite_watcher: yarn watch\n```\n\n### 4. Register the Vite runners\n\nChange the scripts section in `package.json` to use vite instead of laravel mix:\n\n```diff\n{\n  // ...\n  \"scripts\": {\n-    \"heroku-postbuild\": \"yarn prod\",\n-    \"dev\": \"yarn run mix\",\n-    \"watch\": \"yarn run mix watch\",\n-    \"prod\": \"yarn run mix --production\",\n+    \"heroku-postbuild\": \"yarn build\",\n+    \"build\": \"yarn run vite build\",\n+    \"watch\": \"yarn run vite build --watch\"\n  },\n  // ...\n}\n```\n\n### Further steps\n\n- if you use the CI workflow for Github Actions, you'll also need to change `yarn prod` into `yarn build` in `ci.yml`\n- you may want to exclude Vite's `outDir` (e.g. `public/assets`) from the repo\n- all the `laravel-mix` dependencies can be removed from from `package.json`\n- `webpack.mix.js` can be removed\n\n## Usage\n\nStart with including the shard in your app first:\n\n```crystal\n# in src/shards.cr\nrequire \"lucky_vite\"\n```\n\n### Tags\n\nThis shard provides three levels of control over the individual Vite tags.\n\n#### Hands-off\n\nThe `vite_entry_tags` macro method serves all your Vite needs, but it gives you the least amount of control over the individual tags that are generated:\n\n```crystal\n# src/components/shared/layout_head.cr\nvite_entry_tags \"main.js\"\n```\n\nIt does a bunch of things. In development, it loads `@vite/client` and the given entry script. Vite will dynamically load any stylesheets imported in the entry script.\n\nIn production, it will load the static versions from the manifest and create individual tags for all of them, including stylesheets. With this macro, the whole frontend is served.\n\nIt also accepts any attributes you'd want on all the generated tags:\n\n```crystal\nvite_entry_tags \"main.js\", data_turbo_track: \"reload\"\n```\n\nOne downside is that the attributes will be applied to all generated tags, which you may not want in some cases.\n\n#### A bit of control\n\nIf you need different attribtues on style tags than on script tags, you can use the following three methods:\n\n```crystal\nvite_client_tag\nvite_js_link \"main.js\"\nvite_css_link \"main.css\"\n```\n\nTogether they do the exact same thing as `vite_entry_tags`.\n\n**Node**: `vite_css_link` won't output anything in development as stylesheets are dynamically loaded by Vite.\n\n#### Full control\n\nIf you need even more control over the generated tags, you can use the `asset` macro in combination with Lucky's `js_link` and `css_link` methods:\n\n```crystal\nvite_client_tag\njs_link vite_asset(\"main.js\"), type: \"module\"\ncss_link vite_asset(\"main.css\") unless LuckyEnv.development?\n```\n\nThe example above does the exact same thing as `vite_entry_tags`.\n\n### Using React\n\nIf you're using React with the `@vitejs/plugin-react` plugin, you need to add the `vite_react_refresh_tag` method before any other asset tags to inject the refresh runtime served by Vite:\n\n```crystal\nvite_react_refresh_tag\nvite_client_tag\n# ...\n```\n\n### Static assets\n\nLuckyVite manages the asset pipeline by overwriting Lucky's `asset` and `dynamic_asset` macros.\n\n```crystal\nimg src: asset(\"@images/logo.png\")\n```\n\n**Node**: The asset helper uses Vite's aliases for easier referencing. Aliases can be configured in `config/lucky_vite.json`.\n\n## Configuration\n\nLucky and Vite share some information which is managed through the `config/lucky_vite.json` file. It comes with the following defaults:\n\n```json\n{\n  \"aliases\": [\n    \"css\",\n    \"fonts\",\n    \"images\",\n    \"js\"\n  ],\n  \"outDir\": \"public/assets\",\n  \"root\": \"src/js\",\n  \"entry\": \"entry\",\n  \"host\": \"127.0.0.1\",\n  \"port\": 3010\n}\n```\n\nHere's a bit more info about the available properties:\n\n- **`aliases`** (_`string[]`_): a list of directories for Vite to create aliases\n  - _default_: `[\"js\", \"css\", \"images\", \"fonts\"]`)\n  - _example_: `@images` becomes `src/images`\n- **`outDir`** (_`string`_): the target dir for Vite\n  - _default_: `\"public/assets\"`\n  - _note_: this will be cleared on every run\n- **`root`** (_`string`_): the javascript root\n  - _default_: `\"src/js\"`\n- **`entry`** (_`string`_): this is where Vite looks for entry scripts\n  - _default_: `\"entry\"`\n- **`https`** (_`boolean`_): uses `https:` for the Vite server if set to `true`\n  - _default_: `false`\n- **`host`** (_`string | boolean`_): host name for the Vite server\n  - _default_: `\"127.0.0.1\"`\n  - _note_: if set to `true`, it will listen on `0.0.0.0` (all addresses)\n- **`port`** (_`string | number`_): port for the Vite server\n  - _default_: `3010`\n- **`origin`** (_`string`_): alternative to using `https`, `host` and `port`\n  - _example_: `\"http://localhost:3210\"`\n\n**Node**: Not all Vite's configuration options are recognised here as this file covers that's shared between Vite and Lucky. You can add other Vite-specific configuration options directly in `vite.config.js`.\n\n## Documentation\n\n- [API (main)](https://wout.github.io/lucky_vite/)\n\n## Development\n\nMake sure you have [Guardian.cr](https://github.com/f/guardian) installed. Then run:\n\n```bash\n$ guardian\n```\n\nThis will automatically:\n- run ameba for src and spec files\n- run the relevant spec for any file in src\n- run spec file whenever they are saved\n\n## Contributing\n\nWe use [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) for our commit messages, so please adhere to that pattern.\n\n1. Fork it (<https://github.com/wout/lucky_vite/fork>)\n2. Create your feature branch (`git checkout -b my-new-feature`)\n3. Commit your changes (`git commit -am 'feat: new feature'`)\n4. Push to the branch (`git push origin my-new-feature`)\n5. Create a new Pull Request\n\n## Contributors\n\n- [Wout](https://github.com/wout) - creator and maintainer\n","program":{"html_id":"lucky_vite/toplevel","path":"toplevel.html","kind":"module","full_name":"Top Level Namespace","name":"Top Level Namespace","abstract":false,"locations":[],"repository_name":"lucky_vite","program":true,"enum":false,"alias":false,"const":false,"types":[{"html_id":"lucky_vite/Lucky","path":"Lucky.html","kind":"module","full_name":"Lucky","name":"Lucky","abstract":false,"locations":[{"filename":"src/lucky_vite/lucky.cr","line_number":3,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/lucky.cr#L3"}],"repository_name":"lucky_vite","program":false,"enum":false,"alias":false,"const":false,"types":[{"html_id":"lucky_vite/Lucky/BaseComponent","path":"Lucky/BaseComponent.html","kind":"class","full_name":"Lucky::BaseComponent","name":"BaseComponent","abstract":true,"superclass":{"html_id":"lucky_vite/Reference","kind":"class","full_name":"Reference","name":"Reference"},"ancestors":[{"html_id":"lucky_vite/LuckyVite/Tags","kind":"module","full_name":"LuckyVite::Tags","name":"Tags"},{"html_id":"lucky_vite/Reference","kind":"class","full_name":"Reference","name":"Reference"},{"html_id":"lucky_vite/Object","kind":"class","full_name":"Object","name":"Object"}],"locations":[{"filename":"src/lucky_vite/lucky.cr","line_number":10,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/lucky.cr#L10"}],"repository_name":"lucky_vite","program":false,"enum":false,"alias":false,"const":false,"included_modules":[{"html_id":"lucky_vite/LuckyVite/Tags","kind":"module","full_name":"LuckyVite::Tags","name":"Tags"}],"namespace":{"html_id":"lucky_vite/Lucky","kind":"module","full_name":"Lucky","name":"Lucky"}},{"html_id":"lucky_vite/Lucky/HTMLPage","path":"Lucky/HTMLPage.html","kind":"module","full_name":"Lucky::HTMLPage","name":"HTMLPage","abstract":false,"locations":[{"filename":"src/lucky_vite/lucky.cr","line_number":4,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/lucky.cr#L4"}],"repository_name":"lucky_vite","program":false,"enum":false,"alias":false,"const":false,"namespace":{"html_id":"lucky_vite/Lucky","kind":"module","full_name":"Lucky","name":"Lucky"}}]},{"html_id":"lucky_vite/LuckyVite","path":"LuckyVite.html","kind":"module","full_name":"LuckyVite","name":"LuckyVite","abstract":false,"locations":[{"filename":"src/lucky_vite/config.cr","line_number":1,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/config.cr#L1"},{"filename":"src/lucky_vite/main.cr","line_number":1,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/main.cr#L1"},{"filename":"src/lucky_vite/version.cr","line_number":1,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/version.cr#L1"}],"repository_name":"lucky_vite","program":false,"enum":false,"alias":false,"const":false,"constants":[{"id":"VERSION","name":"VERSION","value":"{{ (`shards version \\\"/home/runner/work/lucky_vite/lucky_vite/src/lucky_vite\\\"`).chomp.stringify }}"}],"extended_modules":[{"html_id":"lucky_vite/LuckyVite","kind":"module","full_name":"LuckyVite","name":"LuckyVite"}],"instance_methods":[{"html_id":"config(file=\"config/lucky_vite.json\")-instance-method","name":"config","doc":"Loads and parsed the Lucky Vite config.","summary":"<p>Loads and parsed the Lucky Vite config.</p>","abstract":false,"args":[{"name":"file","default_value":"\"config/lucky_vite.json\"","external_name":"file","restriction":""}],"args_string":"(file = \"config/lucky_vite.json\")","args_html":"(file = <span class=\"s\">&quot;config/lucky_vite.json&quot;</span>)","location":{"filename":"src/lucky_vite/main.cr","line_number":7,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/main.cr#L7"},"def":{"name":"config","args":[{"name":"file","default_value":"\"config/lucky_vite.json\"","external_name":"file","restriction":""}],"visibility":"Public","body":"@@config || (@@config = Config.from_json(File.open(file)))"}},{"html_id":"origin_with_path(path:String)-instance-method","name":"origin_with_path","doc":"Builds a origin uri and appends the given path.","summary":"<p>Builds a origin uri and appends the given path.</p>","abstract":false,"args":[{"name":"path","external_name":"path","restriction":"String"}],"args_string":"(path : String)","args_html":"(path : String)","location":{"filename":"src/lucky_vite/main.cr","line_number":12,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/main.cr#L12"},"def":{"name":"origin_with_path","args":[{"name":"path","external_name":"path","restriction":"String"}],"visibility":"Public","body":"config.to_uri.tap do |uri|\n  if path\n    uri.path = path\n  end\nend.to_s"}}],"types":[{"html_id":"lucky_vite/LuckyVite/AssetHelpers","path":"LuckyVite/AssetHelpers.html","kind":"module","full_name":"LuckyVite::AssetHelpers","name":"AssetHelpers","abstract":false,"locations":[{"filename":"src/lucky_vite/asset_helpers.cr","line_number":1,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/asset_helpers.cr#L1"}],"repository_name":"lucky_vite","program":false,"enum":false,"alias":false,"const":false,"constants":[{"id":"ASSET_MANIFEST","name":"ASSET_MANIFEST","value":"{} of String => NamedTuple(file: String) | NamedTuple(file: String, css: Array(String))"},{"id":"CONFIG","name":"CONFIG","value":"{has_loaded_manifest: false}"}],"namespace":{"html_id":"lucky_vite/LuckyVite","kind":"module","full_name":"LuckyVite","name":"LuckyVite"},"class_methods":[{"html_id":"dynamic_asset(path:String):String-class-method","name":"dynamic_asset","doc":"Return the string path to an asset (allows string interpolation).\n\n```\n# In a page or component\n# Will find the asset in `public/assets/images/logo.a1b2c3d4.png`\nimg src: dynamic_asset(\"images/logo.png\")\n\n# Can also be used elsewhere by prepending LuckyVite::AssetHelpers\nLuckyVite::AssetHelpers.dynamic_asset(\"images/logo.png\")\n```\n\nNOTE: This method does *not* check assets at compile time. The asset path\nis found at runtime so it is possible the asset does not exist. Be sure to\nmanually test that the asset is returned as expected.","summary":"<p>Return the string path to an asset (allows string interpolation).</p>","abstract":false,"args":[{"name":"path","external_name":"path","restriction":"String"}],"args_string":"(path : String) : String","args_html":"(path : String) : String","location":{"filename":"src/lucky_vite/asset_helpers.cr","line_number":99,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/asset_helpers.cr#L99"},"def":{"name":"dynamic_asset","args":[{"name":"path","external_name":"path","restriction":"String"}],"return_type":"String","visibility":"Public","body":"entry = LuckyVite::AssetHelpers::ASSET_MANIFEST[path]? || (raise(\"Asset missing from Vite manifest: #{path}\"))\nFile.join(Lucky::Server.settings.asset_host, entry[:file])\n"}}],"macros":[{"html_id":"asset(path)-macro","name":"asset","doc":"Return the string path to an asset.\n\n```\n# In a page or component:\n# Will find the asset in `public/assets/images/logo.a1b2c3d4.png`\nimg src: asset(\"images/logo.png\")\n\n# Can also be used elsewhere by prepending LuckyVite::AssetHelpers\nLuckyVite::AssetHelpers.asset(\"images/logo.png\")\n```\n\nNote that assets are checked at compile time so if it is not found, Lucky\nwill let you know. It will also let you know if you had a typo and suggest\nan asset that is close to what you typed.\n\nNOTE: This macro requires a `StringLiteral`. That means you cannot\ninterpolate strings like this: `asset(\"images/icon-#{modifier}.png\")`.\ninstead use `dynamic_asset` if you need string interpolation.","summary":"<p>Return the string path to an asset.</p>","abstract":false,"args":[{"name":"path","external_name":"path","restriction":""}],"args_string":"(path)","args_html":"(path)","location":{"filename":"src/lucky_vite/asset_helpers.cr","line_number":37,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/asset_helpers.cr#L37"},"def":{"name":"asset","args":[{"name":"path","external_name":"path","restriction":""}],"visibility":"Public","body":"    File.join(\n      Lucky::Server.settings.asset_host,\n      LuckyVite::AssetHelpers.manifest_entry(\n{{ path }}\n)[:file]\n    )\n  \n"}},{"html_id":"load_manifest(config_file=\"\")-macro","name":"load_manifest","doc":"Runs a macro which parses the manifest.json file generated by Vite.\n\n```\n# In src/app.cr comment out the native manifest loader and add:\nLuckyVite::AssetHelpers.load_manifest(\"public/assets/manifest.json\")\n```\n\nNote: Vite generates its manifest inside the assets dir.","summary":"<p>Runs a macro which parses the manifest.json file generated by Vite.</p>","abstract":false,"args":[{"name":"config_file","default_value":"\"\"","external_name":"config_file","restriction":""}],"args_string":"(config_file = \"\")","args_html":"(config_file = <span class=\"s\">&quot;&quot;</span>)","location":{"filename":"src/lucky_vite/asset_helpers.cr","line_number":14,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/asset_helpers.cr#L14"},"def":{"name":"load_manifest","args":[{"name":"config_file","default_value":"\"\"","external_name":"config_file","restriction":""}],"visibility":"Public","body":"    \n{{ run(\"../lucky_vite_runners/asset_manifest_builder\", config_file) }}\n\n    \n{% CONFIG[:has_loaded_manifest] = true %}\n\n  \n"}},{"html_id":"manifest_entry(path)-macro","name":"manifest_entry","doc":"Safely gets an entry from the Vite manifest and raises a compile time\nerror. It will also let you know if you had a typo and suggest an asset\nthat is close to what you typed.","summary":"<p>Safely gets an entry from the Vite manifest and raises a compile time error.</p>","abstract":false,"args":[{"name":"path","external_name":"path","restriction":""}],"args_string":"(path)","args_html":"(path)","location":{"filename":"src/lucky_vite/asset_helpers.cr","line_number":47,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/asset_helpers.cr#L47"},"def":{"name":"manifest_entry","args":[{"name":"path","external_name":"path","restriction":""}],"visibility":"Public","body":"    \n{% if CONFIG[:has_loaded_manifest] %}{% else %}\n      {% raise(\"No manifest loaded. Call 'LuckyVite::AssetHelpers.load_manifest'\") %}\n    {% end %}\n\n\n    \n{% if path.is_a?(StringLiteral) %}\n      {% if LuckyVite::AssetHelpers::ASSET_MANIFEST[path] %}\n        {{ LuckyVite::AssetHelpers::ASSET_MANIFEST[path] }}\n      {% else %}\n        {% asset_paths = LuckyVite::AssetHelpers::ASSET_MANIFEST.keys.join(\",\") %}\n        {{ run(\"../lucky_vite_runners/missing_asset\", path, asset_paths) }}\n      {% end %}\n    {% else %}{% if path.is_a?(StringInterpolation) %}\n      {% raise(\"\\n\\nThe 'asset' macro doesn't work with string interpolation\\n\\nTry this...\\n\\n  ▸ Use the 'dynamic_asset' method instead\\n\") %}\n    {% else %}\n      {% raise(\"\\n\\nThe 'asset' macro requires a literal string like \\\"app.ts\\\", instead got: #{path}\\n\\nTry this...\\n\\n  ▸ If you're using a variable, switch to a literal string\\n  ▸ If you can't use a literal string, use the 'dynamic_asset' method instead\\n\") %}\n    {% end %}{% end %}\n\n  \n"}}]},{"html_id":"lucky_vite/LuckyVite/Config","path":"LuckyVite/Config.html","kind":"struct","full_name":"LuckyVite::Config","name":"Config","abstract":false,"superclass":{"html_id":"lucky_vite/Struct","kind":"struct","full_name":"Struct","name":"Struct"},"ancestors":[{"html_id":"lucky_vite/JSON/Serializable","kind":"module","full_name":"JSON::Serializable","name":"Serializable"},{"html_id":"lucky_vite/Struct","kind":"struct","full_name":"Struct","name":"Struct"},{"html_id":"lucky_vite/Value","kind":"struct","full_name":"Value","name":"Value"},{"html_id":"lucky_vite/Object","kind":"class","full_name":"Object","name":"Object"}],"locations":[{"filename":"src/lucky_vite/config.cr","line_number":1,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/config.cr#L1"}],"repository_name":"lucky_vite","program":false,"enum":false,"alias":false,"const":false,"included_modules":[{"html_id":"lucky_vite/JSON/Serializable","kind":"module","full_name":"JSON::Serializable","name":"Serializable"}],"namespace":{"html_id":"lucky_vite/LuckyVite","kind":"module","full_name":"LuckyVite","name":"LuckyVite"},"constructors":[{"html_id":"new(pull:JSON::PullParser)-class-method","name":"new","abstract":false,"args":[{"name":"pull","external_name":"pull","restriction":"::JSON::PullParser"}],"args_string":"(pull : JSON::PullParser)","args_html":"(pull : JSON::PullParser)","location":{"filename":"src/lucky_vite/config.cr","line_number":2,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/config.cr#L2"},"def":{"name":"new","args":[{"name":"pull","external_name":"pull","restriction":"::JSON::PullParser"}],"visibility":"Public","body":"new_from_json_pull_parser(pull)"}}],"instance_methods":[{"html_id":"to_uri:URI-instance-method","name":"to_uri","abstract":false,"location":{"filename":"src/lucky_vite/config.cr","line_number":9,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/config.cr#L9"},"def":{"name":"to_uri","return_type":"URI","visibility":"Public","body":"@origin ? URI.parse(@origin.to_s) : URI.new(scheme, host, port)"}}]},{"html_id":"lucky_vite/LuckyVite/Tags","path":"LuckyVite/Tags.html","kind":"module","full_name":"LuckyVite::Tags","name":"Tags","abstract":false,"locations":[{"filename":"src/lucky_vite/tags.cr","line_number":1,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/tags.cr#L1"}],"repository_name":"lucky_vite","program":false,"enum":false,"alias":false,"const":false,"constants":[{"id":"SERVED_BY_VITE","name":"SERVED_BY_VITE","value":"[\"js\", \"jsx\", \"ts\", \"tsx\", \"css\", \"scss\", \"less\"] of ::String"}],"including_types":[{"html_id":"lucky_vite/Lucky/BaseComponent","kind":"class","full_name":"Lucky::BaseComponent","name":"BaseComponent"}],"namespace":{"html_id":"lucky_vite/LuckyVite","kind":"module","full_name":"LuckyVite","name":"LuckyVite"},"instance_methods":[{"html_id":"vite_client_tag(**options)-instance-method","name":"vite_client_tag","doc":"Renders the Vite client to enable Hot Module Reload in development.","summary":"<p>Renders the Vite client to enable Hot Module Reload in development.</p>","abstract":false,"location":{"filename":"src/lucky_vite/tags.cr","line_number":5,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/tags.cr#L5"},"def":{"name":"vite_client_tag","double_splat":{"name":"options","external_name":"options","restriction":""},"visibility":"Public","body":"if LuckyEnv.development?\nelse\n  return\nend\njs_link(LuckyVite.origin_with_path(\"@vite/client\"), **options, type: \"module\")\n"}},{"html_id":"vite_react_refresh_tag(**options)-instance-method","name":"vite_react_refresh_tag","doc":"Loads `/@react-refresh` from the vite server and renders a script tag with\nthe refresh hook.\n\n```\n# In a page or component:\nvite_react_refresh_tag\n```\n\nOnly use this tag with `@vitejs/plugin-react`.","summary":"<p>Loads <code>/@react-refresh</code> from the vite server and renders a script tag with the refresh hook.</p>","abstract":false,"location":{"filename":"src/lucky_vite/tags.cr","line_number":81,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/tags.cr#L81"},"def":{"name":"vite_react_refresh_tag","double_splat":{"name":"options","external_name":"options","restriction":""},"visibility":"Public","body":"if LuckyEnv.development?\nelse\n  return\nend\nscript(**options, type: \"module\") do\n  raw(\"  import RefreshRuntime from '#{LuckyVite.origin_with_path(\"@react-refresh\")}'\\n  RefreshRuntime.injectIntoGlobalHook(window)\\n  window.$RefreshReg$ = () => {}\\n  window.$RefreshSig$ = () => (type) => type\\n  window.__vite_plugin_react_preamble_installed__ = true\")\nend\n"}}],"macros":[{"html_id":"asset(entry)-macro","name":"asset","doc":"Loads an asset from the vite server in development or as a static file in\nproduction.","summary":"<p>Loads an asset from the vite server in development or as a static file in production.</p>","abstract":false,"args":[{"name":"entry","external_name":"entry","restriction":""}],"args_string":"(entry)","args_html":"(entry)","location":{"filename":"src/lucky_vite/tags.cr","line_number":51,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/tags.cr#L51"},"def":{"name":"asset","args":[{"name":"entry","external_name":"entry","restriction":""}],"visibility":"Public","body":"    asset_for_current_environment(\n{{ entry }}\n, asset)\n  \n"}},{"html_id":"dynamic_asset(entry)-macro","name":"dynamic_asset","doc":"Loads an asset, without checking it's existance in the manifest, from the\nvite server in development or as a static file in production.","summary":"<p>Loads an asset, without checking it's existance in the manifest, from the vite server in development or as a static file in production.</p>","abstract":false,"args":[{"name":"entry","external_name":"entry","restriction":""}],"args_string":"(entry)","args_html":"(entry)","location":{"filename":"src/lucky_vite/tags.cr","line_number":57,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/tags.cr#L57"},"def":{"name":"dynamic_asset","args":[{"name":"entry","external_name":"entry","restriction":""}],"visibility":"Public","body":"    asset_for_current_environment(\n{{ entry }}\n, dynamic_asset)\n  \n"}},{"html_id":"vite_css_link(entry,**options)-macro","name":"vite_css_link","doc":"Generates a stylesheet link tag for the given entrypoint.\n\nAdditional tag attributes can be passed in as named arguments.","summary":"<p>Generates a stylesheet link tag for the given entrypoint.</p>","abstract":false,"args":[{"name":"entry","external_name":"entry","restriction":""}],"args_string":"(entry, **options)","args_html":"(entry, **options)","location":{"filename":"src/lucky_vite/tags.cr","line_number":43,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/tags.cr#L43"},"def":{"name":"vite_css_link","args":[{"name":"entry","external_name":"entry","restriction":""}],"double_splat":{"name":"options","external_name":"options","restriction":""},"visibility":"Public","body":"    unless LuckyEnv.development?\n      css_link LuckyVite::AssetHelpers.asset(\n{{ entry }}\n)\n{% if options.empty? %}{% else %}, {{ **options }}{% end %}\n\n    \nend\n  \n"}},{"html_id":"vite_entry_tags(entry,**options)-macro","name":"vite_entry_tags","doc":"A one-stop shop for all your vite tags in development and production.\n\nAdditional tag attributes can be passed in as named arguments.\n\nNote: in development this method connects with the vite server; in other\nenvironments it loads compiled files from the manifest.","summary":"<p>A one-stop shop for all your vite tags in development and production.</p>","abstract":false,"args":[{"name":"entry","external_name":"entry","restriction":""}],"args_string":"(entry, **options)","args_html":"(entry, **options)","location":{"filename":"src/lucky_vite/tags.cr","line_number":17,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/tags.cr#L17"},"def":{"name":"vite_entry_tags","args":[{"name":"entry","external_name":"entry","restriction":""}],"double_splat":{"name":"options","external_name":"options","restriction":""},"visibility":"Public","body":"    if LuckyEnv.development?\n      vite_client_tag(\n{{ **options }}\n)\n      vite_js_link \n{{ entry }}\n{% if options.empty? %}{% else %}, {{ **options }}{% end %}\n\n    \nelse\n      asset = LuckyVite::AssetHelpers.manifest_entry(\n{{ entry }}\n)\n      js_link asset[:file], type: \"module\"\n{% if options.empty? %}{% else %}, {{ **options }}{% end %}\n\n\n      if styles = asset[:css]?\n        styles.each do |file|\n          css_link file\n{% if options.empty? %}{% else %}, {{ **options }}{% end %}\n\n        \nend\n      \nend\n    \nend\n  \n"}},{"html_id":"vite_js_link(entry,**options)-macro","name":"vite_js_link","doc":"Generates a script tag for the given entrypoint.\n\nAdditional tag attributes can be passed in as named arguments.","summary":"<p>Generates a script tag for the given entrypoint.</p>","abstract":false,"args":[{"name":"entry","external_name":"entry","restriction":""}],"args_string":"(entry, **options)","args_html":"(entry, **options)","location":{"filename":"src/lucky_vite/tags.cr","line_number":36,"url":"https://github.com/wout/lucky_vite/blob/ac4e9c373cd34db189211468826dbca171c64bd6/src/lucky_vite/tags.cr#L36"},"def":{"name":"vite_js_link","args":[{"name":"entry","external_name":"entry","restriction":""}],"double_splat":{"name":"options","external_name":"options","restriction":""},"visibility":"Public","body":"    js_link asset(\n{{ entry }}\n), type: \"module\"\n{% if options.empty? %}{% else %}, {{ **options }}{% end %}\n\n  \n"}}]}]}]}})