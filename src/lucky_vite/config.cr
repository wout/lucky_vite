require "json"

struct LuckyVite::Config
  include JSON::Serializable

  @host : Bool | String = "127.0.0.1"
  @port : Int32 | String = 3010
  @https : Bool = false
  @origin : String?

  def to_uri : URI
    @origin ? URI.parse(@origin.to_s) : URI.new(scheme, host, port)
  end

  private def scheme
    @https ? "https" : "http"
  end

  private def host
    @host.is_a?(Bool) ? "0.0.0.0" : @host.to_s
  end

  private def port
    @port.to_i
  end
end
