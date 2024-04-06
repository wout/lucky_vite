require "json"
require "colorize"

private struct LuckyViteAssetManifestBuilder
  CONFIG_PATH = "./config/lucky_vite.json"
  MAX_RETRIES =   20
  RETRY_AFTER = 0.25

  property retries = 0
  getter manifest_path : String
  getter config : LuckyViteConfig
  getter alias_regex : Regex

  def initialize(config_path : String?)
    @config = load_config(config_path)
    @manifest_path = resolve_manifest_path
    @alias_regex = /^\.\.\/\.\.\/(#{config.aliases.join("|")})/
  end

  def build_with_retry
    retry_or_raise_error unless manifest_exists?

    build_manifest
  end

  private def load_config(path : String?)
    path = path.nil? || path.blank? ? CONFIG_PATH : path
    LuckyViteConfig.from_json(File.open(File.expand_path(path)))
  end

  private def resolve_manifest_path
    dir = File.join(config.out_dir, ".vite")

    File.expand_path(
      File.join(Dir.exists?(dir) ? dir : config.out_dir, "manifest.json")
    )
  end

  private def retry_or_raise_error
    raise_missing_manifest_error unless retries < MAX_RETRIES

    self.retries += 1
    sleep(RETRY_AFTER)
    build_with_retry
  end

  private def build_manifest
    parse_manifest.each do |key, value|
      entry = {file: expand_asset_path(value["file"].as_s)}
      if css = parse_stylesheets(value)
        entry = entry.merge({css: css})
      end
      puts %({% LuckyVite::AssetHelpers::ASSET_MANIFEST["#{alias_asset_key(key)}"] = #{entry} %})
    end
  end

  private def parse_stylesheets(value)
    return unless css = value["css"]?.try(&.as_a?)

    css.map { |file| expand_asset_path(file.as_s) }
  end

  private def expand_asset_path(file : String)
    File.join("/", config.assets_dir, file)
  end

  private def alias_asset_key(key : String)
    return key unless key.match(@alias_regex)

    key.gsub(/^\.\.\/\.\.\//, "@")
  end

  private def parse_manifest
    JSON.parse(File.read(manifest_path)).as_h
  end

  private def manifest_exists?
    File.exists?(manifest_path)
  end

  private def raise_missing_manifest_error
    puts "Manifest at #{manifest_path} does not exist".colorize(:red)
    puts "Make sure you have compiled your assets".colorize(:red)
  end

  struct LuckyViteConfig
    include JSON::Serializable

    @assets_dir : String?

    @[JSON::Field(key: "outDir")]
    getter out_dir : String = "public/assets"
    getter aliases : Array(String) = %w[js css images fonts]

    def assets_dir
      @assets_dir ||= out_dir.gsub(/^(\.\/)?public\/?/, "")
    end
  end
end

begin
  LuckyViteAssetManifestBuilder.new(ARGV[0]?).build_with_retry
rescue e
  puts e.message.colorize(:red)
  raise e
end
