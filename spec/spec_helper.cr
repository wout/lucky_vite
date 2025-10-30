require "spec"
require "lucky"
require "lucky_env"
require "../src/lucky_vite"

LuckyVite::AssetHelpers.load_manifest("public/manifest.json")

def read_fixture(file : String) : IO
  path = "#{__DIR__}/fixtures/#{file}"

  File.exists?(path) ||
    raise Exception.new("Fixture #{file} does not exist.")

  File.open(path)
end
