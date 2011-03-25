require 'spec_helper'

describe APIManager::Google do
  it "has an API_ENDPOINT constant" do
    APIManager::Google.const_defined?(:API_ENDPOINT).should be_true
  end
  
  describe ".new" do 
    context "with an access token" do
      before :each do
        @token = "foobar"
      end
      
      it "creates a new Google APIManager" do
        APIManager::Google.new(@token).should be_a(APIManager::Google)
      end
      
      it "stores the token in the oauth_token instance variable" do
        APIManager::Google.new(@token).oauth_token.should == @token
      end

      it "does not allow writing to the oauth_token variable" do
        APIManager::Google.new(@token).oauth_token.should_not respond_to(:oauth_token=)
      end      
    end
    
    context "without an access token" do
      it "raises an error with a '' token" do
        expect {APIManager::Google.new('')}.to raise_exception(ArgumentError)
      end
      
      it "raises an error with a nil token" do
        expect {APIManager::Google.new(nil)}.to raise_exception(ArgumentError)
      end
    end
  end
  
  describe "#auth_url" do
    it "generatees a URL pointing to the right endpoint" do
      APIManager::Google.auth_url.should include("https://accounts.google.com/o/oauth2/auth")
    end
    
    it "generatees a URL pointing to the right scope" do
      APIManager::Google.auth_url.should include("scope=#{APIManager::Google::API_ENDPOINT}")
    end
    
    it "generates a URL with the right client_id parameter" do
      old_key = GOOGLE_AUTH["key"]
      GOOGLE_AUTH["key"] = "bar"
      APIManager::Google.auth_url.should include("client_id=#{GOOGLE_AUTH["key"]}")
      GOOGLE_AUTH["key"] = old_key
    end

    it "generatees a URL with the right redirect URL" do
      old_callback = GOOGLE_AUTH["callback"]
      GOOGLE_AUTH["callback"] = "foo"
      APIManager::Google.auth_url.should include("redirect_uri=#{GOOGLE_AUTH["callback"]}")
      GOOGLE_AUTH["callback"] = old_callback
    end
  end
  
  describe 'service_name' do
    it "should return a string describing the service" do
      APIManager::Google.new("foo").service_name.should =~ /Google/i
    end
  end
  
  describe ".user_info" do
    before :each do
      # the results we should get
      @result = {
        :first => "Alex",
        :last => "Lastname",
        :display => "Alex Lastname",
        :email => "sample@sample.com",
        :identifier => "identifier"
      }
      
      # the mock response from PortableContacts
      @response = {
        "entry" => {
          "name" => {
            "givenName" => @result[:first], 
            "familyName" => @result[:last], 
            "formatted" => "fullname"
          },
          "displayName" => @result[:display], 
          "urls" => [{"type" => "profile", "value" => "url"}], 
          "addresses" => [
            {"type" => "currentLocation", "streetAddress" => "addr", "formatted" => "addr2"},
            {"type" => "currentLocation", "streetAddress" => "addr3", "formatted" => "addr4"}
          ], 
          "id" => @result[:identifier], 
          "emails" => [
            {"value" => "anotherEmail"},
            {"primary" => true, "value" => @result[:email]},
            {"type" => "other", "value" => "yetAnotherEmail"},
            {"type" => "other", "value" => "evenMoreEmail"}
          ], 
          "isViewer" => true,   
          "profileUrl" => "profileurl"
        }
      }
    
      @token = "foobar"
      @google = APIManager::Google.new(@token)
      @google.stubs(:make_request).returns(@response)
    end
    
    it "makes a request for the user" do
      @google.expects(:make_request).with("@self", anything).returns(@response)
      @google.user_info
    end
    
    it "returns a hash with the id as the identifier" do
      @google.user_info[:identifier].should == @result[:identifier]
    end
    
    context "with a primary email" do
      it "returns the primary email address" do
        @response["entry"]["email"] = [
          {"value" => "anotherEmail"},
          {"primary" => true, "value" => @result[:email]},
          {"type" => "other", "value" => "yetAnotherEmail"},
          {"type" => "other", "value" => "evenMoreEmail"}
        ]
        @google.user_info[:email].should == @result[:email]
      end
    end
    
    context "with emails but no primary email" do
      it "returns the first email address" do
        expectant = "anotherEmail"
        @response["entry"]["email"] = [
          {"value" => expectant},
          {"value" => @result[:email]},
          {"type" => "other", "value" => "yetAnotherEmail"},
          {"type" => "other", "value" => "evenMoreEmail"}
        ]
        @google.user_info[:email].should == expectant
      end

    end
    
    context "with no emails" do    
      it "returns nil if emails is nil" do
         @response["entry"]["email"] = nil
         @google.user_info[:email].should be_nil
      end
      
      it "returns nil if it's an array" do
         @response["entry"]["email"] = []
         @google.user_info[:email].should be_nil
      end
      
    end
    
    it "returns a hash with the name as :name" do
      @google.user_info[:name].should == @result[:display]
    end
    
    it "returns a hash with the first name as :first_name" do
      @google.user_info[:first_name].should == @result[:first]
    end
    
    it "returns a hash with the last name as :last_name" do
      @google.user_info[:last_name].should == @result[:last]
    end
    
    it "returns a hash with the account_type set to :google" do
      @google.user_info[:account_type].should == :google
    end
  end
  
  describe ".make_request" do
    it "is private" do
      # make_request is defined generically in APIManager
      APIManager::Google.public_instance_methods.map(&:to_s).should_not include("make_request")
    end
    
    # this tests the internals, but it's important
    it "always sends along the OAuth token as a header" do
      token = "bar"
      g = APIManager::Google.new(token)
      Typhoeus::Request.expects(:get).with(anything, has_entry(:headers => has_entry(:Authorization => "OAuth #{token}"))).returns(Typhoeus::Response.new(:body => "[]"))
      g.send(:make_request, "foo")
    end
  end
end