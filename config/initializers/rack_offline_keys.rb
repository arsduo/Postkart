module Rack
  class Offline
    
    # interval at which to regenerate the cache
    # setting it to 0 or a low value will update the cache key every request
    # which means the manifest will never successfully download
    # (since it gets downloaded twice, and will be changed)
    UNCACHED_KEY_INTERVAL = 10
    
    def call(env)
      key = @key || uncached_key

      body = ["CACHE MANIFEST"]
      body << "# #{key}"
      @config.cache.each do |item|
        body << URI.escape(item.to_s)
      end

      unless @config.network.empty?
        body << "" << "NETWORK:"
        @config.network.each do |item|
          body << URI.escape(item.to_s)
        end
      end

      unless @config.fallback.empty?
        body << "" << "FALLBACK:"
        @config.fallback.each do |namespace, url|
          body << "#{namespace} #{URI.escape(url.to_s)}"
        end
      end

      @logger.debug body.join("\n")

      [200, {"Content-Type" => "text/cache-manifest"}, body.join("\n")]
    end
    
    private
    
    def uncached_key
      now = Time.now.to_i - Time.now.to_i % UNCACHED_KEY_INTERVAL
      Digest::SHA2.hexdigest(now.to_s)
    end
  end
end