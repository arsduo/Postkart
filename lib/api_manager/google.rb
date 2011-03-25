class APIManager
  class Google < APIManager
    attr_reader :oauth_token
    API_ENDPOINT = "https://www-opensocial.googleusercontent.com/api/people/"
    
    def initialize(token)
      @oauth_token = token
      raise ArgumentError, "OAuth token must not be nil!" if @oauth_token.blank?
    end
    
    def service_name
      "Google Contacts"
    end
    
    def user_info
      response = make_request("@self", :params => {:fields => "addresses,emails,name,displayName,id"})["entry"]
      {
        :identifier => response["id"],
        :first_name => response["name"]["givenName"],
        :last_name => response["name"]["familyName"],
        :name => response["displayName"],
        :email => (response["emails"] ? (response["emails"].find {|e| e["primary"]} || response["emails"].first) : {})["value"],
        :account_type => :google
      }
    end
    
    # class methods
    def self.auth_url
      "https://accounts.google.com/o/oauth2/auth?client_id=#{GOOGLE_AUTH["key"]}&" + \
        "redirect_uri=#{GOOGLE_AUTH["callback"]}&scope=https://www-opensocial.googleusercontent.com/api/people/&response_type=token"      

    end     
    
    private 
    
    def make_request(url_suffix, params = {}, typhoeus_args = {})
      super("#{API_ENDPOINT}@me/#{url_suffix}", params, typhoeus_args.merge(:headers => {:Authorization => "OAuth #{@oauth_token}"}))
    end
  end
end