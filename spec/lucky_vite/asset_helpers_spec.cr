require "../spec_helper"

describe LuckyVite::AssetHelpers do
  before_all do
    LuckyVite::AssetHelpers.load_manifest("./public/assets/manifest.json")
  end

  describe ".vite_asset" do
    it "returns the fingerprinted path" do
      LuckyVite::AssetHelpers.vite_asset("lucky_logo.png")
        .should eq "/images/lucky_logo.a54cc67e.png"
    end
  end

  describe ".dynamic_vite_asset" do
    it "returns the fingerprinted path" do
      LuckyVite::AssetHelpers.dynamic_vite_asset("lucky_logo.png")
        .should eq "/images/lucky_logo.a54cc67e.png"
    end

    it "raises with a when a file is not in the manifest" do
      expect_raises(Exception, "Missing Vite asset: missing.png") do
        LuckyVite::AssetHelpers.dynamic_vite_asset("missing.png")
      end
    end
  end

  describe ".vite_manifest_entry" do
    it "description" do
    end
  end
end
