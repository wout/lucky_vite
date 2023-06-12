require "../spec_helper"

describe LuckyVite::AssetHelpers do
  before_all do
    LuckyVite::AssetHelpers.load_manifest("./public/assets/manifest.json")
  end

  describe ".asset" do
    it "gets the fingerprinted path" do
      LuckyVite::AssetHelpers.asset("main.js")
        .should eq "/assets/js/main.2d2335c4.js"
      LuckyVite::AssetHelpers.asset("main.css")
        .should eq "/assets/css/main.75de05d8.css"
      LuckyVite::AssetHelpers.asset("@images/image.jpg")
        .should eq "/assets/images/image.9f16cff4.jpg"
    end
  end

  describe ".dynamic_asset" do
    it "get the fingerprinted path" do
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

  describe ".manifest_entry" do
    it "gets the mafinest entry" do
      LuckyVite::AssetHelpers.manifest_entry("main.js").should eq({
        file: "/assets/js/main.2d2335c4.js",
        css:  [
          "/assets/css/main.75de05d8.css",
        ],
      })
      LuckyVite::AssetHelpers.manifest_entry("main.css").should eq({
        file: "/assets/css/main.75de05d8.css",
      })
      LuckyVite::AssetHelpers.manifest_entry("@images/image.jpg").should eq({
        file: "/assets/images/image.9f16cff4.jpg",
      })
    end
  end
end
