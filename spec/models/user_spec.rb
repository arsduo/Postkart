require 'spec_helper'

describe User do
  
  # modules
  it "should be a Mongoid document" do
    User.included_modules.include?(Mongoid::Document).should be_true
  end
  
  it "should include timestamps" do
    User.included_modules.include?(Mongoid::Timestamps).should be_true
  end
  
  # associations
  it { should embed_many(:remote_accounts) }
  it { should reference_many(:trips) }
  it { should reference_many(:recipients) }
  it { should reference_many(:mailings) }
  
  describe "#from_google_token" do
    before :each do
      @token = "foo"
      @sample_data = {
        :identifier => "sample@sample.com", 
        :email => "sample@sample.com", 
        :name => "Alex"
      }

      # stub out the APIManager
      @mgr = APIManager::Google.new(@token)
      APIManager::Google.stubs(:new).returns(@mgr)
      @mgr.stubs(:user_info).returns(@sample_data)

      # we currently do optimization with limit, but don't let that interfere
      # harmless if the implementation changes
      User.stubs(:limit).returns(User)
    end
    
    it "instantiates a Google API manager" do
      APIManager::Google.expects(:new).with(@token).returns(@mgr)
      User.from_google_token(@token)
    end
    
    it "gets user_info from the API manager" do
      @mgr.expects(:user_info).returns(@sample_data)
      User.from_google_token(@token)
    end
    
    it "looks for the user based on the identifier" do
      User.expects(:where).with(has_value(@sample_data[:identifier])).returns([])
      User.from_google_token(@token)
    end

    context "for a new user" do
      
    end
    
    context "for an existing user" do
      it "returns the existing user" do
        u = User.new
        # this should use User.make, then search based on the access token
        User.stubs(:where).returns([u])
        User.from_google_token(@token).should == u
      end
      
      it "updates the user's remote account with the new token"
    end    
  end
  
end
