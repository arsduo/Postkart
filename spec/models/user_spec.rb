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
  
end
