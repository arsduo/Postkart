class APIManager
  class Google < APIManager
    attr_reader :oauth_token
    API_ENDPOINT = "https://www.google.com/m8/feeds/contacts/default/full/"
    
    def initialize(token)
      @oauth_token = token
      raise ArgumentError, "OAuth token must not be nil!" if @oauth_token.blank?
    end
    
    def service_name
      "Google Contacts"
    end
    
    def user_info
      result = make_request(:max_results => 0)
      author = result["feed"]["author"][0]
      name = author["name"]["$t"]
      email = author["email"]["$t"]
      {:identifier => email, :email => email, :name => name}
    end     
    
    # class methods
    def self.auth_url
      "https://accounts.google.com/o/oauth2/auth?client_id=#{GOOGLE_AUTH["key"]}&" + \
        "redirect_uri=#{GOOGLE_AUTH["callback"]}&scope=https://www.google.com/m8/feeds/&response_type=token"      

    end     
    
    private 
    
    def make_request(params = {})
      super(API_ENDPOINT, :alt => :json, :oauth_token => @oauth_token, "max-results" => params[:max_results])
    end
  end
end