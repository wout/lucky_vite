require "colorize"
require "json"
require "levenshtein"

missing_asset = ARGV.first
asset_paths = ARGV[1].split(",")

best_match = Levenshtein::Finder.find missing_asset, asset_paths, tolerance: 4

puts %("#{missing_asset}" does not exist in the manifest.).colorize(:red)

if best_match
  puts %(Did you mean "#{best_match}"?).colorize(:yellow).bold
else
  puts "Make sure the asset exists and you have compiled your assets.".colorize(:red)
end

raise "There was a problem finding the asset"
