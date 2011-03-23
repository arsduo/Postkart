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
      APIManager::Google.auth_url.should include("scope=https://www.google.com/m8/feeds/")
    end

    it "generatees a URL with the right scope" do
      APIManager::Google.auth_url.should include("scope=https://www.google.com/m8/feeds/")
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
      # Google's overly-complex result structure
      @response = {
        "feed" => {
          "author" => [{
              "name" => { "$t" => "Alex" },
              "email" => { "$t" => "sample@example.com" }
          }]
        }
      }
    
      @token = "foobar"
      @google = APIManager::Google.new(@token)
      @google.stubs(:make_request).returns(@response)
    end
    
    it "makes a request with max-results 0" do
      @google.expects(:make_request).with(:max_results => 0).returns(@response)
      @google.user_info
    end
    
    it "returns a hash with the email address as :identifier" do
      @google.user_info[:identifier].should == @response["feed"]["author"][0]["email"]["$t"]
    end
    
    it "returns a hash with the email address as :email" do
      @google.user_info[:email].should == @response["feed"]["author"][0]["email"]["$t"]
    end
    
    it "returns a hash with the name as :name" do
      @google.user_info[:name].should == @response["feed"]["author"][0]["name"]["$t"]
    end
  end
  
  describe ".make_request" do
    it "is private" do
      # make_request is defined generically in APIManager
      APIManager::Google.public_instance_methods.map(&:to_s).should_not include("make_request")
    end
  end
end