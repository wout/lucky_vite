require "../spec_helper"

describe LuckyVite::Config do
  it "parses the http scheme" do
    test_config.to_uri.scheme.should eq("http")
    test_config("deviating").to_uri.scheme.should eq("https")
    test_config("origin").to_uri.scheme.should eq("http")
  end

  it "parses the host" do
    test_config.to_uri.host.should eq("127.0.0.1")
    test_config("deviating").to_uri.host.should eq("0.0.0.0")
    test_config("origin").to_uri.host.should eq("localhost")
  end

  it "parses the port" do
    test_config.to_uri.port.should eq(3010)
    test_config("deviating").to_uri.port.should eq(2222)
    test_config("origin").to_uri.port.should eq(3210)
  end
end

private def test_config(fixture = "default")
  LuckyVite::Config.from_json(read_fixture("config/#{fixture}.json"))
end
