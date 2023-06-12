require "../spec_helper"

describe LuckyVite::AssetHelpers do
  before_all do
    LuckyVite::AssetHelpers.load_manifest("./public/assets/manifest.json")
  end

  describe ".asset" do
    it "returns the fingerprinted path" do
      LuckyVite::AssetHelpers.asset("main.js")
        .should eq "/assets/js/main.2d2335c4.js"
      LuckyVite::AssetHelpers.asset("main.css")
        .should eq "/assets/css/main.75de05d8.css"
      LuckyVite::AssetHelpers.asset("@images/image.jpg")
        .should eq "/assets/images/image.9f16cff4.jpg"
    end
  end

  describe ".dynamic_asset" do
    it "returns the fingerprinted path" do
      LuckyVite::AssetHelpers.dynamic_asset("main.js")
        .should eq "/assets/js/main.2d2335c4.js"
      LuckyVite::AssetHelpers.dynamic_asset("main.css")
        .should eq "/assets/css/main.75de05d8.css"
      LuckyVite::AssetHelpers.dynamic_asset("@images/image.jpg")
        .should eq "/assets/images/image.9f16cff4.jpg"
    end

    it "raises with a when a file is not in the manifest" do
      expect_raises(
        Exception, "Asset missing from Vite manifest: @images/missing.png"
      ) do
        LuckyVite::AssetHelpers.dynamic_asset("@images/missing.png")
      end
    end
  end

  describe ".vite_manifest_entry" do
    it "description" do
    end
  end
end
