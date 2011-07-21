require 'spec_helper'

describe APIManager::Google do
  include ContactsTestHelper
  
  it "has an API_ENDPOINT constant" do
    APIManager::Google.const_defined?(:API_ENDPOINT).should be_true
  end
  
  describe ".new" do 
    context "with an access token" do
      before :each do
        @args = {:token => "foobar"}
      end
      
      it "creates a new Google APIManager" do
        APIManager::Google.new(@args).should be_a(APIManager::Google)
      end
      
      it "stores the token in the oauth_token instance variable" do
        APIManager::Google.new(@args).oauth_token.should == @args[:token]
      end

      it "does not allow writing to the oauth_token variable" do
        APIManager::Google.new(@args).oauth_token.should_not respond_to(:oauth_token=)
      end
    end
    
    context "with a code" do
      before :each do
        @args = {:code => "foobar"}
      end
      
      it "creates a new Google APIManager" do
        APIManager::Google.new(@args).should be_a(APIManager::Google)
      end
      
      it "fetches the token"
    end
    
    context "without an access token or a code" do
      it "raises an error" do
        expect {APIManager::Google.new()}.to raise_exception(ArgumentError)
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
      APIManager::Google.new(:token => "foo").service_name.should =~ /Google/i
    end
  end
  
  describe ".user_info" do
    before :each do
      @token = "foobar"
      @google = APIManager::Google.new(:token => @token)
      @google.stubs(:make_authorized_request).returns({"entry" => "bar"})

      # don't do parsing
      @google.stubs(:parse_portable_contact)
    end
    
    it "makes a request for the user" do
      @google.expects(:make_authorized_request).with("@self", anything)
      @google.user_info
    end
    
    it "makes a request for the right fields" do
      @google.expects(:make_authorized_request).with(anything, :fields => APIManager::Google::FIELDS)
      @google.user_info
    end
    
    it "uses parse_portable_contact to parse the results" do
      result = {"entry" => "bar"}
      @google.stubs(:make_authorized_request).returns(result)
      @google.expects(:parse_portable_contact).with(result["entry"])
      @google.user_info
    end
  end
  
  describe ".user_contacts" do
    before :each do
      @token = "foobar"
      @google = APIManager::Google.new(:token => @token)
      @google.stubs(:make_authorized_request).returns({"entry" => "bar"})

      # the results we should get
      @results = []
      @responses = {"entry" => []}
      # set up sample portable contact groups
      10.times do |i| 
        result, response = sample_portable_contact
        @results << result
        @responses["entry"] << response
      end
    end
    
    it "makes a request for the user's mycontacts group" do
      @google.expects(:make_authorized_request).with("mycontacts", anything).returns(@responses)
      @google.user_contacts
    end
    
    it "makes a request for the right fields" do
      @google.expects(:make_authorized_request).with(anything, has_entries(:fields => APIManager::Google::FIELDS)).returns(@responses)
      @google.user_contacts
    end
    
    it "makes a request for a lot of contacts" do
      @google.expects(:make_authorized_request).with(anything, has_entries(:count => APIManager::Google::CONTACT_COUNT)).returns(@responses)
      @google.user_contacts
    end
    
    
    it "parses all the contacts returned" do
      parsing_responses = sequence(:parsing_responses)
      @responses["entry"].each {|e| @google.expects(:parse_portable_contact).with(e).in_sequence(parsing_responses)}
      @google.stubs(:make_authorized_request).returns(@responses)      
      @google.user_contacts
    end
    
    it "returns the parsed results" do
      parsing_responses = sequence(:parsing_responses)
      return_value = []
      @responses["entry"].each_with_index do |e, i| 
        @google.stubs(:parse_portable_contact).with(e).returns(i)
        return_value << i
      end

      @google.stubs(:make_authorized_request).returns(@responses)      
      @google.user_contacts.should == return_value
    end
    
    it "returns the proper values for parsing" do
      # this is a bit unnecessary, since we test parse_contacts below
      # but it probably doesn't hurt
      @google.stubs(:make_authorized_request).returns(@responses)      
      @google.user_contacts.should == @results
    end
  end
  
  describe ".make_authorized_request" do
    before :each do
      @token = "bar"
      @google = APIManager::Google.new(:token => @token)
    end
    
    it "is private" do
      # make_authorized_request is defined generically in APIManager
      APIManager::Google.public_instance_methods.map(&:to_s).should_not include("make_authorized_request")
    end
    
    # this tests the internals, but it's important
    it "always makes a GET request" do
      Typhoeus::Request.expects(:get).with(anything, anything).returns(Typhoeus::Response.new(:body => "[]", :code => 200))
      @google.send(:make_authorized_request, "foo")
    end
    
    it "always sends along the OAuth token as a header" do
      Typhoeus::Request.expects(:get).with(anything, has_entry(:headers => has_entry(:Authorization => "OAuth #{@token}"))).returns(Typhoeus::Response.new(:body => "[]", :code => 200))
      @google.send(:make_authorized_request, "foo")
    end
    
    it "raises an InvalidTokenError if it gets an APIError whose message =~ /Invalid AuthSub token/" do
      Typhoeus::Request.expects(:get).returns(Typhoeus::Response.new(
        :body => "<HTML>\n  <HEAD>\n  <TITLE>Failed to verify 3 legged OAuth request. Request was invalid.Invalid AuthSub token.</TITLE>\n  </HEAD>\n  <BODY BGCOLOR=\"#FFFFFF\" TEXT=\"#000000\">\n  <H1>Failed to verify 3 legged OAuth request. Request was invalid.Invalid AuthSub token.</H1>\n  <H2>Error 401</H2>\n  </BODY>\n  </HTML>",
        :code => 401
      ))
      expect { @google.send(:make_authorized_request, "foo") }.to raise_exception(APIManager::Google::InvalidTokenError)
    end
  end
  
  describe ".parse_portable_contact" do
    it "is private" do
      # make_authorized_request is defined generically in APIManager
      APIManager::Google.public_instance_methods.map(&:to_s).should_not include("parse_portable_contact")
    end
    
    # sure, it's private
    # but we don't care how it works, just that this method does what it should
    before :each do
      # the results we should get
      @result, @response = sample_portable_contact
      
      @token = "foobar"
      @google = APIManager::Google.new(:token => @token)
      @google.stubs(:make_authorized_request).returns(@response)
    end
    
    it "raises a MalformedPortableContactError if the result is not a hash" do
      expect { @google.send(:parse_portable_contact, nil) }.to raise_exception(APIManager::Google::MalformedPortableContactError)
    end
    
    it "raises a MalformedPortableContactError if the result is a hash without the right sub-hashes" do
      expect { @google.send(:parse_portable_contact, {}) }.to raise_exception(APIManager::Google::MalformedPortableContactError)
    end
    
    it "returns a hash with the id as the id" do
      @google.send(:parse_portable_contact, @response)[:id].should == @result[:id]
    end

    context "with a primary email" do
      it "returns the primary email address" do
        @response["emails"] = [
          {"value" => "anotherEmail"},
          {"primary" => true, "value" => @result[:email]},
          {"type" => "other", "value" => "yetAnotherEmail"},
          {"type" => "other", "value" => "evenMoreEmail"}
        ]
        @google.send(:parse_portable_contact, @response)[:email].should == @result[:email]
      end
    end

    context "with emails but no primary email" do
      it "returns the first email address" do
        expectant = "anotherEmail"
        @response["emails"] = [
          {"value" => expectant},
          {"value" => @result[:email]},
          {"type" => "other", "value" => "yetAnotherEmail"},
          {"type" => "other", "value" => "evenMoreEmail"}
        ]
        @google.send(:parse_portable_contact, @response)[:email].should == expectant
      end

    end

    context "with no emails" do    
      it "returns nil if emails is nil" do
         @response["emails"] = nil
         @google.send(:parse_portable_contact, @response)[:email].should be_nil
      end

      it "returns nil if it's an array" do
         @response["emails"] = []
         @google.send(:parse_portable_contact, @response)[:email].should be_nil
      end

    end

    it "returns a hash with the name as :name" do
      @google.send(:parse_portable_contact, @response)[:name].should == @result[:name]
    end

    it "returns a hash with the first name as :first_name" do
      @google.send(:parse_portable_contact, @response)[:first_name].should == @result[:first_name ]
    end

    it "returns a hash with the last name as :last_name" do
      @google.send(:parse_portable_contact, @response)[:last_name].should == @result[:last_name]
    end

    it "returns a hash with the account_type set to :google" do
      @google.send(:parse_portable_contact, @response)[:account_type].should == :google
    end
    
    it "collects all the formatted addresses into an array" do
      @google.send(:parse_portable_contact, @response)[:addresses].should ==  @response["addresses"].map {|a| a["formatted"]}     
    end
  end
end