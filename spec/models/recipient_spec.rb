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
  it { should have_field(:addr_encrypted) }
  it { should have_field(:city) }
  it { should have_field(:state) }
  it { should have_field(:postal_code) }
  it { should have_field(:country) }
  it { should have_field(:remote_id) }
  it { should have_field(:remote_source, :type => Symbol) }
  
  # associations
  it { should be_referenced_in(:user) }
  it { should reference_many(:mailings) }
  
  # validations
  it { should validate_presence_of(:remote_id) }
  it { should validate_presence_of(:remote_source) }
  it { should validate_inclusion_of(:remote_source, :in => Recipient::SOURCES) }


end
