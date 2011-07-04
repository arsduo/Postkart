class APIManager
  class APIError < StandardError; end
  
  def initialize(*args)
    raise StandardError, "APIManager should not be initialized directly!"
  end

  def service_name
    raise StandardError, "APIManager#service_name should never be called directly! (Called from #{self.class.to_s})"
  end

  def make_request(url, params = {}, typhoeus_args = {})
    begin
      Timeout.timeout(5) do
        response = Typhoeus::Request.get(url, {:params => params}.merge(typhoeus_args))
        response.code == 200 ? MultiJson.decode(response.body) : raise(APIError, response.body)
      end
    rescue Timeout::Error
      unless @retried
        @retried = true
        retry
      else
        Rails.logger.warn("#{service_name} timed out twice!")
        raise
      end
    end
  end
end