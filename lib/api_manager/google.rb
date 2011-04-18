class APIManager
  class Google < APIManager
    attr_reader :oauth_token
    
    API_ENDPOINT = "https://www-opensocial.googleusercontent.com/api/people/"
    FIELDS = "addresses,emails,name,displayName,id,thumbnailUrl"
    CONTACT_COUNT = 1000
    
    class MalformedPortableContactError < APIError; end
    class InvalidTokenError < APIError; end
    
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
      # get as many contacts as we can
      contacts = make_request("mycontacts", :fields => FIELDS, :count => CONTACT_COUNT)["entry"]
      contacts.map {|c| parse_portable_contact(c) rescue nil}
    end
    
    # class methods
    def self.auth_url
      "https://accounts.google.com/o/oauth2/auth?client_id=#{GOOGLE_AUTH["key"]}&" + \
        "redirect_uri=#{GOOGLE_AUTH["callback"]}&scope=https://www-opensocial.googleusercontent.com/api/people/&response_type=token"
    end     
    
    private 
    
    def parse_portable_contact(user)
      begin
        if user.is_a?(Hash)
          {
            :id => user["id"],
            :first_name => user["name"]["givenName"],
            :last_name => user["name"]["familyName"],
            :name => user["displayName"],
            :addresses => (user["addresses"] || []).map {|a| a["formatted"]},
            :email => ((user["emails"] ||= []).find {|e| e["primary"]} || user["emails"].first || {})["value"],
            :pic => user["thumbnailUrl"],
            :account_type => :google
          }
        else
          # we don't have a properly formatted result
          raise MalformedPortableContactError, "Expected a hash but got #{user.inspect}"
        end
      rescue NoMethodError => err
        # if the hash structure doesn't match what we expected, raise an error
        raise MalformedPortableContactError, "Bad content for contact #{user.inspect}" if err.message =~ /You have a nil object/
      end
    end
    
    def make_request(url_suffix, params = {}, typhoeus_args = {})
      begin
        super("#{API_ENDPOINT}@me/#{url_suffix}", params, typhoeus_args.merge(:headers => {:Authorization => "OAuth #{@oauth_token}"}))
      rescue APIError => e
        raise InvalidTokenError if e.message =~ /Invalid AuthSub token/
        raise
      end
    end
  end
end