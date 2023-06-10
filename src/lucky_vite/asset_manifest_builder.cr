require "json"
require "colorize"

private struct LuckyViteAssetManifestBuilder
  CONFIG_PATH = File.expand_path("./config/lucky_vite.json")
  MAX_RETRIES =   20
  RETRY_AFTER = 0.25

  property retries : Int32 = 0
  getter manifest_path : String

  def initialize(path : Nil = nil)
    @manifest_path = manifest_path_from_config
  end

  def initialize(path : String)
    @manifest_path = path.blank? ? manifest_path_from_config : path
  end

  def build_with_retry
    retry_or_raise_error unless manifest_exists?

    build_manifest
  end

  private def manifest_path_from_config
    config = LuckyViteConfig.from_json(File.open(CONFIG_PATH))
    File.expand_path(File.join(config.out_dir, "manifest.json"))
  end

  private def retry_or_raise_error
    raise_missing_manifest_error unless retries < MAX_RETRIES

    self.retries += 1
    sleep(RETRY_AFTER)
    build_with_retry
  end

  private def build_manifest
    parsed_manifest.each do |key, value|
      entry = {file: "/" + value["file"].as_s}
      if css = value["css"]?.try(&.as_a?.try(&.map { |f| "/" + f.as_s }))
        entry = entry.merge({css: css})
      end
      puts %({% LuckyVite::AssetHelpers::ASSET_MANIFEST["#{key}"] = #{entry} %})
    end
  end

  private def parsed_manifest
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

    @[JSON::Field(key: "outDir")]
    getter out_dir : String = "public/assets"
  end
end

begin
  LuckyViteAssetManifestBuilder.new(ARGV[0]?).build_with_retry
rescue e
  puts e.message.colorize(:red)
  raise e
end
