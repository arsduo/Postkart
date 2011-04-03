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
  
  # associations
  it { should be_referenced_in(:user) }
  it { should reference_many(:mailings) }
  
  # validations
  it { should validate_presence_of(:remote_id) }

end
