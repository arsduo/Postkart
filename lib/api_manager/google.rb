module APIManager
  class Google
    
    def initialize(token)
      @oauth_token = token
      raise ArgumentError, "OAuth token must not be nil!" if @oauth_token.blank?
    end
    
    def user_info
      result = make_request(:max_results => 0)
      author = result["feed"]["author"][0]
      name = author["name"]["$t"]
      email = author["email"]["$t"]
      {:identifier => email, :email => email, :name => name}
    end
         
    private 
    
    def make_request(params = {})
      JSON.parse(
        Typhoeus::Request.get("https://www.google.com/m8/feeds/contacts/default/full/", :params => {
          :alt => :json, :oauth_token => @oauth_token, "max-results" => params[:max_results]}
        ).body
      )
    end
  end
end