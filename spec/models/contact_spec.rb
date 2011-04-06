require 'spec_helper'

describe Contact do
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
  it { should have_field(:addresses, :type => Array, :default => []) }
  it { should have_field(:remote_id) }

  it { should have_field(:city) }
  it { should have_field(:state) }
  it { should have_field(:country) }
  
  # associations
  it { should be_referenced_in(:user) }
  it { should reference_many(:mailings) }
  
  # validations
  it { should validate_presence_of(:remote_id) }

  describe "#new_from_remote_contact" do
    before :each do
      @hash = {
        :first_name => Faker::Name.first_name,
        :last_name => Faker::Name.last_name,
        :name => Faker::Name.name,
        :addresses => ["addr1", "addr2"]
      }
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
  end
  
  describe ".update_from_remote_contact" do
    before :each do
      @r = Contact.make
      
      @new_info = {
        :first_name => Faker::Name.first_name,
        :last_name => Faker::Name.last_name,
        :name => Faker::Name.name,
        :addresses => [Faker::Address.street_address],
        :remote_id => Faker::Lorem.words(1).join("")
      }
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
    
    it "saves the record" do
      @r.expects(:save)
      @r.update_from_remote_contact(@new_info)      
    end
  end

end
