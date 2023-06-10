struct LuckyVite::Config
  include JSON::Serializable

  setter host : Bool | String = "127.0.0.1"
  setter port : Int32 | String = 3010
  getter https : Bool = false
  getter origin : String?

  def scheme
    https ? "https" : "http"
  end

  def host
    @host.is_a?(Bool) ? "0.0.0.0" : @host.to_s
  end

  def port
    @port.to_i
  end

  def to_uri
    origin ? URI.parse(origin.to_s) : URI.new(scheme, host, port)
  end
end
