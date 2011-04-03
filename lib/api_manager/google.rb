class APIManager
  class Google < APIManager
    attr_reader :oauth_token
    
    API_ENDPOINT = "https://www-opensocial.googleusercontent.com/api/people/"
    FIELDS = "addresses,emails,name,displayName,id"
    
    class MalformedPortableContactError < StandardError; end
    
    def initialize(token)
      @oauth_token = token
      raise ArgumentError, "OAuth token must not be nil!" if @oauth_token.blank?
    end
    
    def service_name
      "Google Contacts"
    end
    
    def user_info
      user = (make_request("@self", :fields => FIELDS) || {})["entry"]
      parse_portable_contact(user)
    end
    
    def user_contacts
      contacts = make_request("mycontacts", :fields => FIELDS)["entry"]
      processed_contacts = {:with_address => [], :no_address => []}
      contacts.each do |c|
        parsed = parse_portable_contact(c)
        processed_contacts[parsed[:addresses].length > 0 ? :with_address : :no_address] << parsed
      end
      
      processed_contacts
    end
    
    # class methods
    def self.auth_url
      "https://accounts.google.com/o/oauth2/auth?client_id=#{GOOGLE_AUTH["key"]}&" + \
        "redirect_uri=#{GOOGLE_AUTH["callback"]}&scope=https://www-opensocial.googleusercontent.com/api/people/&response_type=token"
    end     
    
    private 
    
    def parse_portable_contact(user)
      if user.is_a?(Hash)
        {
          :id => user["id"],
          :first_name => user["name"]["givenName"],
          :last_name => user["name"]["familyName"],
          :name => user["displayName"],
          :addresses => (user["addresses"] || []).map {|a| a["formatted"]},
          :email => ((user["emails"] ||= []).find {|e| e["primary"]} || user["emails"].first || {})["value"],
          :account_type => :google
        }
      else
        # we don't have a properly formatted result
        raise MalformedPortableContactError
      end
    end
    
    def make_request(url_suffix, params = {}, typhoeus_args = {})
      super("#{API_ENDPOINT}@me/#{url_suffix}", params, typhoeus_args.merge(:headers => {:Authorization => "OAuth #{@oauth_token}"}))
    end
  end
end