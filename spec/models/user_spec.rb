require 'spec_helper'

describe User do
  include PortableContactsTestHelper
  
  # modules
  it "should be a Mongoid document" do
    User.included_modules.include?(Mongoid::Document).should be_true
  end
  
  it "should include timestamps" do
    User.included_modules.include?(Mongoid::Timestamps).should be_true
  end
  
  # fields
  it { should have_field(:name) }
  
  # associations
  it { should embed_many(:remote_accounts) }
  it { should reference_many(:trips) }
  it { should reference_many(:contacts) }
  it { should reference_many(:mailings) }
  
  describe "#find_or_create_from_google_token" do
    before :each do
      @token = "foo"
      @sample_data = sample_portable_contact.first

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
    
    it "looks for the user based on the id" do
      User.expects(:where).with(has_value(@sample_data[:id])).returns([])
      User.find_or_create_from_google_token(@token)
    end
    
    shared_examples_for "creating a new remote account" do
      # note: it's expected that the containing context will provide a before block
      # that defines @u as a user object
      before :each do
        @u.remote_accounts.stubs(:where).returns([])
      end

      it "creates a new remote account of type Google with the id and token" do
        r = RemoteAccount.make
        RemoteAccount.expects(:new).with(
          :remote_id => @sample_data[:id],
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
      
      it "saves the new account record" do
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
      
      context "with a remote account" do
        before :each do
          @r = RemoteAccount.make(:user => @u)
          @u.remote_accounts.stubs(:where).returns([@r])
        end
        
        it "updates the remote account" do
          User.find_or_create_from_google_token(@token)
          @r.token.should == @token
        end
        
        it "persists the token change" do          
          User.find_or_create_from_google_token(@token)
          @r.changed?.should be_false
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
  
  describe ".google_api" do
    before :each do
      @user = User.make
    end
    
    context "if there is a Google remote account" do
      it "initializes a Google API with the token in the google remote account" do
        # figure out what the token is
        token = @user.remote_accounts.where(:account_type => :google).first.token
        g = APIManager::Google.new("foo")
        APIManager::Google.expects(:new).with(token).returns(g)
        @user.google_api
      end

      it "returns the existing api if it's been initialized" do
        g = @user.google_api
        APIManager::Google.expects(:new).never
        @user.google_api.should == g
      end
    end
    
    it "returns nil if there is no remote account" do
      @user.remote_accounts.destroy_all
      @user.google_api.should be_nil
    end
  end
  
  describe ".populate_google_contacts" do
    before :each do
      @user = User.make
      
      @google = stub("Google API")
      @user.stubs(:google_api).returns(@google)
      @contact_hashes = 10.times.inject([]) {|array, i| array << sample_portable_contact.first}
      @google.stubs(:user_contacts).returns(@contact_hashes)
    end
    
    it "gets the user's contacts" do
      @user.expects(:google_api).returns(@google)
      @google.expects(:user_contacts).returns([])
      @user.populate_google_contacts
    end
    
    it "looks up each contact by remote_id to see if it exists" do
      contact_lookup = sequence(:contact_lookup)
      @contact_hashes.each do |c| 
        temp_contact = Contact.new_from_remote_contact(c)
        # Contact#generate_remote_id is the PortableContact => unique ID generator
        @user.contacts.expects(:where).with(:remote_id => Contact.generate_remote_id(c)).returns([temp_contact]).in_sequence(contact_lookup)
      end
      @user.populate_google_contacts
    end
    
    it "returns a hash with three arrays" do
      result = @user.populate_google_contacts
      result[:updated_with_address].should be_an(Array)
      result[:updated_without_address].should be_an(Array)
      result[:unimportable].should be_an(Array)
    end
    
    context "for contacts that couldn't be processed" do
      before :each do
        @google.stubs(:user_contacts).returns([nil])
      end
      
      it "puts the bad contact into the unimportable array" do
        @user.populate_google_contacts[:unimportable].should include(nil)
      end
      
      it "doesn't do any other processing" do
        Contact.expects(:generate_remote_id).never
        @user.populate_google_contacts
      end
    end
    
    context "for contacts that exist" do
      before :each do
        @contact_info = @contact_hashes.first
        @contact = Contact.new_from_remote_contact(@contact_info)
        @user.contacts.stubs(:where).returns([])
        @user.contacts.stubs(:where).with(:remote_id => @contact.remote_id).returns([@contact])        
      end
      
      it "updates contacts that already exist" do
        # other contacts will be treated as new ones
        @contact.expects(:update_from_remote_contact).with(@contact_info)
        @user.populate_google_contacts 
      end

      it "adds that contact to the :updated_with_address bucket if it has an address" do
        # we don't want to process the update, which changes the addresses
        @contact.stubs(:update_from_remote_contact) 

        @contact.addresses = ["abc"]
        @user.populate_google_contacts[:updated_with_address].should include(@contact)
      end
      
      it "adds that contact to the :updated_without_address bucket if it has an address" do
        # we don't want to process the update, which changes the addresses
        @contact.stubs(:update_from_remote_contact) 

        @contact.addresses = []
        @user.populate_google_contacts[:updated_without_address].should include(@contact)
      end
    end
    
    context "for new contacts" do
      before :each do
        @contact_info = @contact_hashes.first
        @contact = Contact.new
        Contact.stubs(:new_from_remote_contact).returns(@contact)

        # set up one contact from the group to be a new contact
        @user.contacts.stubs(:where).returns([Contact.new])
        @user.contacts.stubs(:where).with(:remote_id => @contact_info[:id]).returns([])        
      end
      
      it "creates a new contact from the remote contact" do
        Contact.expects(:new_from_remote_contact).with(@contact_info).returns(@contact)
        @user.populate_google_contacts 
      end
      
      context "if there's a remote_id" do
        before :each do
          @contact.stubs(:remote_id).returns("fooBar")
        end

        it "adds the contact to the user if there's a remote_id" do
          @user.populate_google_contacts
          @user.contacts.include?(@contact).should be_true
        end

        it "saves the contact there's a remote_id" do
          @user.populate_google_contacts
          @contact.new_record?.should be_false
        end

        it "adds the contact to the :updated_with_address bucket if it has an address" do
          @contact.stubs(:addresses).returns(["a"])
          @user.populate_google_contacts[:updated_with_address].should include(@contact)
        end

        it "adds that contact to the :updated_without_address bucket if it has no addresses" do
          @contact.stubs(:addresses).returns([])
          @user.populate_google_contacts[:updated_without_address].should include(@contact)
        end
      end
      
      context "if there is no remote_id" do
        before :each do
          @contact.stubs(:remote_id)
        end
        
        it "adds that contact to the :updated_without_address bucket if it has an address" do
          @user.populate_google_contacts[:unimportable].should include(@contact)
        end
        
        it "does not save the record" do
          @user.populate_google_contacts
          @contact.new_record?.should be_true
        end
      end
    end
    
  end
  
end