module LuckyVite::Tags
  # Renders the Vite client to enable Hot Module Reload in development.
  def vite_client_tag
    return unless LuckyEnv.development?

    js_link(LuckyVite.origin_with_path("@vite/client"), type: "module")
  end

  # A one-stop shop for all your vite tags in development and production.
  #
  # Additional tag attributes can be passed in as keyword arguments via
  # the *options* `NamedTuple`.
  #
  # Note: in development this method connects with the vite server; in other
  # environments it loads compiled files from the manifest.
  macro vite_entry_tags(entry, options)
    if LuckyEnv.development?
      vite_client_tag
      vite_js_link({{entry}}, {{options}})
    else
      asset = LuckyVite::AssetHelpers.vite_manifest_entry({{entry}})
      js_link asset[:file], type: "module", {{**options}}

      if styles = asset[:css]?
        styles.each do |file|
          css_link file, {{**options}}
        end
      end
    end
  end

  # Generates a script tag for the given entrypoint.
  #
  # Additional tag attributes can be passed in as keyword arguments via the
  # *options* `NamedTuple`.
  macro vite_js_link(entry, options)
    js_link vite_asset({{entry}}), type: "module", {{**options}}
  end

  # Generates a stylesheet link tag for the given entrypoint.
  #
  # Additional tag attributes can be passed in keyword arguments via the
  # *options* `NamedTuple`.
  macro vite_css_link(entry, options)
    unless LuckyEnv.development?
      css_link LuckyVite::AssetHelpers.vite_asset({{entry}}), {{**options}}
    end
  end

  # Loads an asset from the vite server in development or as a static file in
  # production.
  macro vite_asset(entry)
    if LuckyEnv.development?
      LuckyVite.origin_with_path({{entry}})
    else
      LuckyVite::AssetHelpers.vite_asset({{entry}})
    end
  end

  # Loads `/@react-refresh` from the vite server and renders a script tag with
  # the refresh hook.
  #
  # ```
  # # In a page or component:
  # vite_react_refresh_tag
  # ```
  #
  # Only use this tag with `@vitejs/plugin-react`.
  def vite_react_refresh_tag
    script type: "module" do
      raw <<-REACT
        import RefreshRuntime from '#{LuckyVite.origin_with_path("@react-refresh")}'
        RefreshRuntime.injectIntoGlobalHook(window)
        window.$RefreshReg$ = () => {}
        window.$RefreshSig$ = () => (type) => type
        window.__vite_plugin_react_preamble_installed__ = true
      REACT
    end
  end
end
