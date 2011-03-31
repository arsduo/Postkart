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
  
  describe "#find_or_create_from_google_token" do
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
      User.find_or_create_from_google_token(@token)
    end
    
    it "gets user_info from the API manager" do
      @mgr.expects(:user_info).returns(@sample_data)
      User.find_or_create_from_google_token(@token)
    end
    
    it "looks for the user based on the identifier" do
      User.expects(:where).with(has_value(@sample_data[:identifier])).returns([])
      User.find_or_create_from_google_token(@token)
    end
    
    shared_examples_for "creating a new remote account" do
      # note: it's expected that the containing context will provide a before block
      # that defines @u as a user object
      before :each do
        @u.remote_accounts.stubs(:where).returns([])
      end

      it "creates a new remote account of type Google with the identifier and token" do
        r = RemoteAccount.make
        RemoteAccount.expects(:new).with(
          :identifier => @sample_data[:identifier],
          :token => @token,
          :account_type => :google
        ).returns(r)
        User.find_or_create_from_google_token(@token)
      end

      it "adds that account to the user" do
        r = RemoteAccount.make
        RemoteAccount.stubs(:new).returns(r)
        @u.remote_accounts.expects(:<<).with(r)
        User.find_or_create_from_google_token(@token)
      end      
    end

    context "for a new user" do
      before :each do
        User.stubs(:where).returns([])
        @u = User.make
        User.stubs(:new).returns(@u)
      end
      
      it "creates a user record with the specified name" do
        User.expects(:new).with(:name => @sample_data[:name]).returns(@u)
        User.find_or_create_from_google_token(@token)
      end
      
      it "saves the user record" do
        @u.expects(:save)
        User.find_or_create_from_google_token(@token)
      end
      
      it "returns the newly-created user record" do
        User.find_or_create_from_google_token(@token).should == @u
      end
      
      it_should_behave_like "creating a new remote account"
    end
    
    context "for an existing user" do
      before :each do
        @u = User.make
        # this should use User.make, then search based on the access token
        User.stubs(:where).returns([@u])
        @u.stubs(:new_record?).returns(false)
      end
      
      it "returns the existing user" do
        User.find_or_create_from_google_token(@token).should == @u
      end
      
      it "saves the user record" do
        @u.expects(:save)
        User.find_or_create_from_google_token(@token)
      end
      
      context "with a remote account" do
        before :each do
          @r = RemoteAccount.make
          @u.remote_accounts.stubs(:where).returns([@r])
        end
        
        it "updates the remote account" do
          User.find_or_create_from_google_token(@token)
          @r.token.should == @token
        end
      end
      
      context "with no remote account" do
        before :each do
          @u.remote_accounts.stubs(:where).returns([])
        end
        
        it_should_behave_like "creating a new remote account"
      end
    end
  end
  
end