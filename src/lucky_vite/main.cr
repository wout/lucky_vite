module LuckyVite
  extend self

  @@config : Config?

  # Loads and parsed the Lucky Vite config.
  def config(file = "config/lucky_vite.json")
    @@config ||= Config.from_json(File.open(file))
  end

  # Builds a origin uri and appends the given path.
  def origin_with_path(path : String)
    config.to_uri.tap do |uri|
      uri.path = path if path
    end.to_s
  end
end
