require 'spec_helper'

describe Recipient do
  # modules
  it "should be a Mongoid document" do
    Recipient.included_modules.include?(Mongoid::Document).should be_true
  end
  
  it "should include timestamps" do
    Recipient.included_modules.include?(Mongoid::Timestamps).should be_true
  end
  
  # fields
  it { should have_field(:first_name) }
  it { should have_field(:last_name) }
  it { should have_field(:addresses, :type => Array) }
  it { should have_field(:remote_id) }

  it { should have_field(:city) }
  it { should have_field(:state) }
  it { should have_field(:country) }
  
  # associations
  it { should be_referenced_in(:user) }
  it { should reference_many(:mailings) }
  
  # validations
  it { should validate_presence_of(:remote_id) }

  describe "#from_remote_contact" do
    before :each do
      @hash = {
        :first_name => Faker::Name.first_name,
        :last_name => Faker::Name.last_name,
        :name => Faker::Name.name,
        :addresses => ["addr1", "addr2"]
      }
    end
    
    it "returns a new Recipient" do # whose first_name is hash[:first_name]" do
      r = Recipient.from_remote_contact(@hash)
      r.should be_a(Recipient)
      r.new_record?.should be_true
    end

    it "returns a new Recipient whose first_name is hash[:first_name]" do
      Recipient.from_remote_contact(@hash).first_name.should == @hash[:first_name]
    end

    it "returns a new Recipient whose last_name is hash[:last_name]" do
      Recipient.from_remote_contact(@hash).last_name.should == @hash[:last_name]
    end
    
    it "returns a new Recipient whose name is hash[:name]" do
      Recipient.from_remote_contact(@hash).name.should == @hash[:name]
    end

    it "returns a new Recipient whose addresses are hash[:addresses]" do
      Recipient.from_remote_contact(@hash).addresses.should == @hash[:addresses]
    end

    it "returns a new Recipient whose remote_id is the appropriate value" do
      id = "foo"
      Recipient.expects(:generate_remote_id).with(@hash).returns(id)
      Recipient.from_remote_contact(@hash).remote_id.should == id
    end    
  end

  describe "#generate_remote_id" do
    it "returns the id if provided" do
      remote_id = "bar"
      Recipient.generate_remote_id({:id => remote_id}).should == remote_id
    end
    
    it "returns a hash of the email address if there's no ID" do
      email = "foo@bar.com"
      Recipient.generate_remote_id({:email => email}).should == Digest::MD5.hexdigest(email)
    end

    it "returns a hash of the name + street address if there's no ID or email" do
      name = Faker::Name.name
      address = "#{Faker::Address.street_address}, Main City, #{Faker::Address.zip_code}"
      Recipient.generate_remote_id({:name => name, :addresses => [address]}).should == Digest::MD5.hexdigest(name + address)
    end
    
    it "returns nil if none of those are available" do
      Recipient.generate_remote_id({}).should be_nil
    end
  end

end
