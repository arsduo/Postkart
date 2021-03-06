require 'spec_helper'

describe Contact do
  include ContactsTestHelper
  
  # modules
  it "should be a Mongoid document" do
    Contact.included_modules.include?(Mongoid::Document).should be_true
  end
  
  it "should include timestamps" do
    Contact.included_modules.include?(Mongoid::Timestamps).should be_true
  end
  
  # fields
  it { should have_field(:first_name) }
  it { should have_field(:last_name) }
  it { should have_field(:name) }
  it { should have_field(:pic) }
  it { should have_field(:encrypted_addresses, :type => Array, :default => []) }
  it { should have_field(:remote_id) }
  
  # associations
  it { should be_referenced_in(:user) }
  it { should reference_many(:mailings) }
  
  # validations
  it { should validate_presence_of(:remote_id) }

  describe ".client_json" do
    it "generates a hash with only :_id, :first_name, :last_name, and (decrypted) :addresses" do
      c = Contact.make
      c.stubs(:_id).returns("foo")
      json = c.client_json
      json["_id"].should == c._id.to_s
      json["first_name"].should == c.first_name
      json["last_name"].should == c.last_name
      json[:addresses].should == c.addresses
    end
  end

  describe ".addresses=" do
    before :each do
      @contact = Contact.make
    end
    
    it "sets the encrypted address" do
      @contact = Contact.make
      @contact.encrypted_addresses = nil
      @contact.addresses = ["abc"]
      @contact.encrypted_addresses.should_not be_nil
      @contact.encrypted_addresses.length.should == 1
    end
    
    it "wraps the encrypted addresses in BSON::Binaries" do
      @contact.addresses = ["123 Main St., Anytown, USA"]
      @contact.encrypted_addresses.first.should be_a(BSON::Binary)
    end
    
    it "encrypts the addresses using Blowfish and the encryption key" do
      addr = "456 Main St., Anytown, USA"
      @contact.addresses = [addr]
      encrypted_addr = @contact.encrypted_addresses.first
      # we test that it's encrypted by decrypting it, and making sure it works
      Blowfish.decrypt(ENCRYPTION_KEY, encrypted_addr.to_s).should == addr
    end
    
    it "stores nothing on :addresses on the record" do
      @contact.addresses = ["789 Main St., Anytown, USA"]
      @contact[:addresses].should be_nil
      @contact["addresses"].should be_nil
    end
    
    describe "abbreviations" do
      it "shortens United States of America to USA, case insensitively" do
        address = "185 Main St, Anytown, United States of America"
        address2 = "485 Main St, Anytown, united states of america"
        @contact.addresses = [address, address2]
        @contact.addresses.first.should == "185 Main St, Anytown, USA"
        @contact.addresses.last.should == "485 Main St, Anytown, USA"
      end
      
      it "shortens United States to USA,  case insensitively" do
        address = "385 Main St, Anytown, United States"
        address2 = "585 Main St, Anytown, united states"
        @contact.addresses = [address, address2]
        @contact.addresses.first.should == "385 Main St, Anytown, USA"
        @contact.addresses.last.should == "585 Main St, Anytown, USA"
      end
    end
  end
  
  describe ".addresses" do
    it "decrypts information stored using addresses=" do
      @contact = Contact.make
      addresses = ["145 Main St., Anytown, USA"]
      @contact.addresses = addresses
      @contact.addresses.should == addresses
    end
  end
  
  describe "#new_from_remote_contact" do
    before :each do
      @hash = sample_portable_contact.first
    end
    
    it "returns a new Contact" do # whose first_name is hash[:first_name]" do
      r = Contact.new_from_remote_contact(@hash)
      r.should be_a(Contact)
      r.new_record?.should be_true
    end

    it "returns a new Contact whose first_name is hash[:first_name]" do
      Contact.new_from_remote_contact(@hash).first_name.should == @hash[:first_name]
    end

    it "returns a new Contact whose last_name is hash[:last_name]" do
      Contact.new_from_remote_contact(@hash).last_name.should == @hash[:last_name]
    end
    
    it "returns a new Contact whose name is hash[:name]" do
      Contact.new_from_remote_contact(@hash).name.should == @hash[:name]
    end
    
    it "returns a new Contact whose pic is hash[:pic]" do
      Contact.new_from_remote_contact(@hash).pic.should == @hash[:pic]
    end

    it "returns a new Contact whose addresses are hash[:addresses]" do
      Contact.new_from_remote_contact(@hash).addresses.should == @hash[:addresses]
    end

    it "returns a new Contact whose remote_id is the appropriate value" do
      id = "foo"
      Contact.expects(:generate_remote_id).with(@hash).returns(id)
      Contact.new_from_remote_contact(@hash).remote_id.should == id
    end    
  end

  describe "#generate_remote_id" do
    it "returns the id if provided" do
      remote_id = "bar"
      Contact.generate_remote_id({:id => remote_id}).should == remote_id
    end
    
    it "returns a hash of the email address if there's no ID" do
      email = "foo@bar.com"
      Contact.generate_remote_id({:email => email}).should == Digest::MD5.hexdigest(email)
    end

    it "returns a hash of the name + street address if there's no ID or email" do
      name = Faker::Name.name
      address = "#{Faker::Address.street_address}, Main City, #{Faker::Address.zip_code}"
      Contact.generate_remote_id({:name => name, :addresses => [address]}).should == Digest::MD5.hexdigest(name + address)
    end
    
    it "returns nil if none of those are available" do
      Contact.generate_remote_id({}).should be_nil
    end
    
    it "returns nil if name is present but address is nil" do
      Contact.generate_remote_id({:name => "foo"}).should be_nil
    end
    
  end
  
  describe ".update_from_remote_contact" do
    before :each do
      @r = Contact.make
      
      @new_info = sample_portable_contact.first
    end
    
    it "updates the first name" do
      @r.update_from_remote_contact(@new_info)
      @r.first_name.should == @new_info[:first_name]
    end

    it "updates the last name" do
      @r.update_from_remote_contact(@new_info)
      @r.last_name.should == @new_info[:last_name]
    end

    it "updates the name field" do
      @r.update_from_remote_contact(@new_info)
      @r.name.should == @new_info[:name]
    end

    it "updates the addresses" do
      @r.update_from_remote_contact(@new_info)
      @r.addresses.should == @new_info[:addresses]
    end
    
    it "updates the pic" do
      @r.update_from_remote_contact(@new_info)
      @r.pic.should == @new_info[:pic]
    end
    
    it "saves the record" do
      @r.expects(:save)
      @r.update_from_remote_contact(@new_info)      
    end
  end

end
