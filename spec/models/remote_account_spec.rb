require 'spec_helper'

describe RemoteAccount do
  # modules
  it "should be a Mongoid document" do
    Mailing.included_modules.include?(Mongoid::Document).should be_true
  end
  
  it "should include timestamps" do
    Mailing.included_modules.include?(Mongoid::Timestamps).should be_true
  end

  # EMBEDDED
  it { should be_embedded_in(:user) }
  
  # REFERENCES
  it { should be_referenced_in(:recipient) }
  
  # FIELDS
  it { should have_field(:account_type, :type => Symbol) }
  it { should have_field(:identifier) }
  it { should have_field(:token) }
  
 # VALIDATIWONS
 it { should validate_presence_of(:identifier) }
 it { should validate_inclusion_of(:account_type, :in => RemoteAccount::TYPES) }
 
end
