require "spec"
require "lucky"
require "../src/lucky_vite"

def read_fixture(file : String) : IO
  path = "#{__DIR__}/fixtures/#{file}"

  File.exists?(path) ||
    raise Exception.new("Fixture #{file} does not exist.")

  File.open(path)
end
