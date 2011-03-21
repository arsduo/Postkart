require 'spec_helper'

describe APIManager::Google do
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
end