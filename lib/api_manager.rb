class APIManager
  def initialize(*args)
    raise StandardError, "APIManager should not be initialized directly!"
  end
  
  def make_request(url, params = {})
    JSON.parse(Typhoeus::Request.get(url, :params => params).body)
  end
end