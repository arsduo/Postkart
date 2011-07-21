require 'spec_helper'

describe User do
  include ContactsTestHelper
  
  # modules
  it "should be a Mongoid document" do
    User.included_modules.include?(Mongoid::Document).should be_true
  end
  
  it "should include timestamps" do
    User.included_modules.include?(Mongoid::Timestamps).should be_true
  end
  
  # fields
  it { should have_field(:name) }
  it { should have_field(:pic) }
  it { should have_field(:accepted_terms, :type => Boolean) }
  it { should have_field(:contacts_updated_at, :type => DateTime) }
  it { should have_field(:trips_updated_at, :type => DateTime) }
  
  # associations
  it { should embed_many(:remote_accounts) }
  it { should reference_many(:trips) }
  it { should reference_many(:contacts) }
  it { should reference_many(:mailings) }
  
  describe ".client_json" do
    it "generates a hash with only :_id, :name" do
      u = User.make
      u.stubs(:_id).returns("foo")
      json = u.client_json
      json["_id"] = u._id
      json["name"] = u.name
    end
  end
  
  describe ".last_update" do
    it "returns contacts_updated_at.to_i if that's newer than trips_updated_at" do
      u = User.make(:contacts_updated_at => Time.now, :trips_updated_at => Time.now - 10)
      u.last_update.should == u.contacts_updated_at.to_i
    end

    it "returns contacts_updated_at.to_i if that's newer than trips_updated_at" do
      u = User.make(:contacts_updated_at => Time.now - 10, :trips_updated_at => Time.now)
      u.last_update.should == u.trips_updated_at.to_i
    end

    it "returns 0 if both are nil" do
      u = User.make(:contacts_updated_at => nil, :trips_updated_at => nil)
      u.last_update.should == 0
    end
  end
  
  describe "#find_or_create_from_google_token" do
    before :each do
      @token = "foo"
      @sample_data = sample_portable_contact.first

      # stub out the APIManager
      @mgr = APIManager::Google.new(:token => @token)
      APIManager::Google.stubs(:new).returns(@mgr)
      @mgr.stubs(:user_info).returns(@sample_data)

      # we currently do optimization with limit, but don't let that interfere
      # harmless if the implementation changes
      User.stubs(:limit).returns(User)
    end
    
    it "instantiates a Google API manager" do
      APIManager::Google.expects(:new).with(:token => @token).returns(@mgr)
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
        RemoteAccount.expects(:new).with(has_entries(
            :identifier => @sample_data[:id],
            :token => @token,
            :account_type => :google
          )
        ).returns(r)
        User.find_or_create_from_google_token(@token)
      end

      it "adds that account to the user" do
        r = RemoteAccount.make
        RemoteAccount.stubs(:new).returns(r)
        User.find_or_create_from_google_token(@token)
        r.user.should == @u
      end      
    end

    context "for a new user" do
      before :each do
        User.stubs(:where).returns([])
        @u = User.make
        User.stubs(:new).returns(@u)
      end
      
      it "creates a user record with the specified name" do
        User.expects(:new).with(has_entries(:name => @sample_data[:name])).returns(@u)
        User.find_or_create_from_google_token(@token)
      end
      
      it "creates a user record with the specified pic" do
        User.expects(:new).with(has_entries(:pic => @sample_data[:pic])).returns(@u)
        User.find_or_create_from_google_token(@token)
      end
      
      it "saves! the new account record" do
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
      
      it "updates the user's name" do
        @sample_data[:name] += @u.name
        @sample_data[:pic] += @u.pic
        User.find_or_create_from_google_token(@token)
        @u.name.should == @sample_data[:name]
      end
      
      it "updates the user's pic" do
        @sample_data[:pic] += @u.pic
        User.find_or_create_from_google_token(@token)
        @u.pic.should == @sample_data[:pic]
      end
            
      it "saves the account record" do
        @u.expects(:save)
        User.find_or_create_from_google_token(@token)
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

    it "can be run twice for the same user without creating multiple users" do
      count = User.count
      User.find_or_create_from_google_token(@token)
      User.find_or_create_from_google_token(@token)
      User.count.should == count + 1 # only one new user
    end
    
    it "can be run twice for the same user without creating multiple remote accounts" do
      u = User.make
      u.remote_accounts.destroy_all
      User.stubs(:where).returns([u])
      User.find_or_create_from_google_token(@token)
      User.find_or_create_from_google_token(@token)
      u.remote_accounts.count == 1 # only one new remote account
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
        g = APIManager::Google.new(:token => "foo")
        APIManager::Google.expects(:new).with(:token => token).returns(g)
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
    
    it "refreshes the Google account if the remote token has been updated"
  end
  
  describe ".populate_google_contacts" do
    before :each do
      @user = User.make
      
      @google = stub("Google API")
      @user.stubs(:google_api).returns(@google)
            
      # set up some contacts
      contact_info = hashes_and_contacts(10, @user)      
      @contact_hashes = []
      @contacts = []
      contact_info.each {|hash, contact| @contact_hashes << hash; @contacts << contact}
    
      @user.stubs(:contacts).returns(@contacts)
      @google.stubs(:user_contacts).returns(@contact_hashes)
    end
    
    it "returns a hash with four arrays" do
      result = @user.populate_google_contacts
      result[:new_with_address].should be_an(Array)
      result[:new_without_address].should be_an(Array)
      result[:updated].should be_an(Array)
      result[:unimportable].should be_an(Array)
    end
    
    it "can run more than once without creating duplicate contacts" do
      # add a few new contacts along and make some changes 
      @contacts.first.addresses = []
      @contact_hashes.concat hashes_and_contacts(2).collect {|hac| hac.first}
      
      @user.populate_google_contacts
      count = @user.contacts.count
      @user.populate_google_contacts
      count.should == @user.contacts.count     
    end
    
    context "for contacts that couldn't be processed" do
      before :each do
        @unusable_contact = {:name => "Alex Koppel", :first_name => "Alex", :last_name => "Koppel"}
        @bad_contacts = [nil, {}, @unusable_contact]
        @google.stubs(:user_contacts).returns(@bad_contacts)
      end
      
      it "puts any contacts w/o sufficient info into the unimportable array" do
        result = @user.populate_google_contacts[:unimportable]
        @bad_contacts.should == [@unusable_contact]
      end
      
      it "doesn't do any other processing" do
        Contact.expects(:generate_remote_id).with(@unusable_contact)
        @user.populate_google_contacts
      end
    end
    
    context "for contacts that exist" do
      before :each do
        # vary up the contacts as may be useful
        @contacts.each_with_index {|c, i| c.addresses = [] if i % 2 }
        @user.contacts_updated_at = Time.now - 2.days
      end
      
      it "updates contacts that already exist" do
        @contacts.each_with_index do |c, i|
          c.expects(:update_from_remote_contact).with(@contact_hashes[i])
        end
        @user.populate_google_contacts 
      end

      it "adds that contact to the appropriate bucket depending on previous address (or not)" do
        result = @user.populate_google_contacts
        @contacts.each do |c|
          result[(c.addresses.blank? ? :new_with_address : :updated)].should include(c)
        end
      end
      
      it "updates the contacts_updated_at date if at least one of the contacts has a newer date" do
        t = Time.now
        Contact.any_instance.stubs(:updated_at).returns(Time.now - 3.days)
        @contacts.first.stubs(:updated_at).returns(t)
        @user.populate_google_contacts
        # we use to_i since we're using a Time here and a DateTime in the model
        @user.contacts_updated_at.to_i.should == t.to_i
        @user.changed?.should be_false
      end
      
      it "does not update the contact if there aren't changes" do
        t = @user.contacts_updated_at
        @contacts.each {|c| c.stubs(:updated_at).returns(Time.now - 4.days) }
        @user.populate_google_contacts 
        @user.contacts_updated_at.should == t
        @user.changed?.should be_false
      end
    end
    
    context "for new contacts" do
      context "if there's a remote_id" do
        before :each do
          # empty out some of the contacts
          @user.stubs(:contacts).returns([])
          
          @contact_hashes.each_with_index do |ch, i|
            # clear some addresses
            @contacts[i].addresses = [] if i % 2 == 0 
            Contact.stubs(:new_from_remote_contact).with(ch).returns(@contacts[i]) 
          end
          
          @user.contacts_updated_at = Time.now - 2.days
        end

        it "creates a new contact from the remote contact" do
          @contact_hashes.each_with_index do |ch, i|
            Contact.expects(:new_from_remote_contact).with(ch).returns(Contact.make) 
          end
          @user.populate_google_contacts 
        end

        it "adds the contact to the user if there's a remote_id" do
          @user.populate_google_contacts
          @contacts.each {|c| @user.contacts.should include(c)}
        end

        it "saves the contact there's a remote_id" do
          Contact.stubs(:new_from_remote_contact).returns(Contact.make) 
          @user.populate_google_contacts
          @user.contacts.each {|c| c.new_record?.should be_false}
        end

        it "adds the contact to the :new_with_address bucket if it has an address" do
          results = @user.populate_google_contacts[:new_with_address]
          @contacts.each_with_index {|c, i| results.send(i % 2 == 0 ? :should_not : :should, include(c)) }
        end

        it "adds that contact to the :updated_without_address bucket if it has no addresses" do
          results = @user.populate_google_contacts[:new_without_address]
          @contacts.each_with_index {|c, i| results.send(i % 2 == 0 ? :should : :should_not, include(c)) }
        end
        
        it "updates the contacts_updated_at date, since this is a new contact" do
          t = Time.now
          Contact.any_instance.stubs(:updated_at).returns(Time.now - 1.days)
          @contacts.last.stubs(:updated_at).returns(t)
          @user.populate_google_contacts
          @user.contacts_updated_at.to_i.should == t.to_i
          @user.changed?.should be_false
        end
      end

      context "if there is no remote_id" do
        before :each do
          # make them all look new and unimportable
          Contact.stubs(:generate_remote_id)
        end
        
        it "adds that contact to the :unimportable bucket" do
          @contact_hashes.each do |c|
            @user.populate_google_contacts[:unimportable].should include(c)
          end
        end
        
        it "does not create a record" do
          Contact.expects(:new).never
          Contact.expects(:create).never
          @user.populate_google_contacts
        end
      end
    end
  end
  
end