module LuckyVite::AssetHelpers
  ASSET_MANIFEST = {} of String => NamedTuple(file: String) |
                                   NamedTuple(file: String, css: Array(String))
  CONFIG = {has_loaded_manifest: false}

  # Runs a macro which parses the manifest.json file generated by Vite.
  #
  # ```
  # # In src/app.cr comment out the native manifest loader and add:
  # LuckyVite::AssetHelpers.load_manifest("public/assets/manifest.json")
  # ```
  #
  # Note: Vite generates its manifest inside the assets dir.
  macro load_manifest(manifest_file)
    {{ run "../lucky_vite_runners/asset_manifest_builder", manifest_file }}
    {% CONFIG[:has_loaded_manifest] = true %}
  end

  # Return the string path to an asset.
  #
  # ```
  # # In a page or component:
  # # Will find the asset in `public/assets/images/logo.a1b2c3d4.png`
  # img src: vite_asset("images/logo.png")
  #
  # # Can also be used elsewhere by prepending LuckyVite::AssetHelpers
  # LuckyVite::AssetHelpers.vite_asset("images/logo.png")
  # ```
  #
  # Note that assets are checked at compile time so if it is not found, Lucky
  # will let you know. It will also let you know if you had a typo and suggest
  # an asset that is close to what you typed.
  #
  # NOTE: This macro requires a `StringLiteral`. That means you cannot
  # interpolate strings like this: `vite_asset("images/icon-#{modifier}.png")`.
  # instead use `dynamic_vite_asset` if you need string interpolation.
  macro vite_asset(path)
    File.join(
      Lucky::Server.settings.asset_host,
      LuckyVite::AssetHelpers.vite_manifest_entry({{path}})[:file]
    )
  end

  # Safely gets an entry from the Vite manifest and raises a compile time
  # error. It will also let you know if you had a typo and suggest an asset
  # that is close to what you typed.
  macro vite_manifest_entry(path)
    {% unless CONFIG[:has_loaded_manifest] %}
      {% raise "No manifest loaded. Call 'LuckyVite::AssetHelpers.load_manifest'" %}
    {% end %}

    {% if path.is_a?(StringLiteral) %}
      {% if LuckyVite::AssetHelpers::ASSET_MANIFEST[path] %}
        {{ LuckyVite::AssetHelpers::ASSET_MANIFEST[path] }}
      {% else %}
        {% asset_paths = LuckyVite::AssetHelpers::ASSET_MANIFEST.keys.join(",") %}
        {{ run "../lucky_vite_runners/missing_asset", path, asset_paths }}
      {% end %}
    {% elsif path.is_a?(StringInterpolation) %}
      {% raise <<-ERROR
      \n
      The 'vite_asset' macro doesn't work with string interpolation

      Try this...

        ▸ Use the 'dynamic_vite_asset' method instead

      ERROR
      %}
    {% else %}
      {% raise <<-ERROR
      \n
      The 'vite_asset' macro requires a literal string like "app.ts", instead got: #{path}

      Try this...

        ▸ If you're using a variable, switch to a literal string
        ▸ If you can't use a literal string, use the 'dynamic_vite_asset' method instead

      ERROR
      %}
    {% end %}
  end

  # Return the string path to an asset (allows string interpolation).
  #
  # ```
  # # In a page or component
  # # Will find the asset in `public/assets/images/logo.a1b2c3d4.png`
  # img src: dynamic_vite_asset("images/logo.png")
  #
  # # Can also be used elsewhere by prepending LuckyVite::AssetHelpers
  # LuckyVite::AssetHelpers.dynamic_vite_asset("images/logo.png")
  # ```
  #
  # NOTE: This method does *not* check assets at compile time. The asset path
  # is found at runtime so it is possible the asset does not exist. Be sure to
  # manually test that the asset is returned as expected.
  def self.dynamic_vite_asset(path)
    entry = LuckyVite::AssetHelpers::ASSET_MANIFEST[path]? ||
            raise "Missing Vite asset: #{path}"

    File.join(Lucky::Server.settings.asset_host, entry[:file])
  end
end
