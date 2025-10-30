module LuckyVite::Tags
  SERVED_BY_VITE = %w[js jsx ts tsx css scss less]

  # Renders the Vite client to enable Hot Module Reload in development.
  def vite_client_tag(**options)
    return unless LuckyEnv.development?

    js_link(LuckyVite.origin_with_path("@vite/client"), **options, type: "module")
  end

  # A one-stop shop for all your vite tags in development and production.
  #
  # Additional tag attributes can be passed in as named arguments.
  #
  # Note: in development this method connects with the vite server; in other
  # environments it loads compiled files from the manifest.
  macro vite_entry_tags(entry, **options)
    if LuckyEnv.development?
      vite_client_tag({{options.double_splat}})
      vite_js_link {{entry}}{% unless options.empty? %}, {{options.double_splat}}{% end %}
    else
      asset = LuckyVite::AssetHelpers.manifest_entry({{entry}})
      js_link asset[:file], type: "module"{% unless options.empty? %}, {{options.double_splat}}{% end %}
      vite_css_links({{entry}}, {{options.double_splat}})
    end
  end

  # Generates a script tag for the given entrypoint.
  #
  # Additional tag attributes can be passed in as named arguments.
  macro vite_js_link(entry, **options)
    js_link asset({{entry}}), type: "module"{% unless options.empty? %}, {{options.double_splat}}{% end %}
  end

  # Generates a stylesheet link tag for the given entrypoint.
  #
  # Additional tag attributes can be passed in as named arguments.
  macro vite_css_links(entry, **options)
    return if LuckyEnv.development?

    asset = LuckyVite::AssetHelpers.manifest_entry({{entry}})

    return unless styles = asset[:css]?

    styles.each do |style|
      file = File.join(Lucky::Server.settings.asset_host, style)
      css_link file{% unless options.empty? %}, {{options.double_splat}}{% end %}
    end
  end

  # Loads an asset from the vite server in development or as a static file in
  # production.
  macro asset(entry)
    asset_for_current_environment({{entry}}, asset)
  end

  # Loads an asset, without checking it's existance in the manifest, from the
  # vite server in development or as a static file in production.
  macro dynamic_asset(entry)
    asset_for_current_environment({{entry}}, dynamic_asset)
  end

  # :nodoc:
  macro asset_for_current_environment(entry, method)
    {% style_or_script = SERVED_BY_VITE.includes?(entry.split(".").last) %}

    if LuckyEnv.development? && {{style_or_script}}
      LuckyVite.origin_with_path({{entry.gsub(/^(@js|@css)\//, "")}})
    else
      LuckyVite::AssetHelpers.{{method}}({{entry}})
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
  def vite_react_refresh_tag(**options)
    return unless LuckyEnv.development?

    script **options, type: "module" do
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
