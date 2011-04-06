require 'spec_helper'

describe Mailing do
  # modules
  it "should be a Mongoid document" do
    Mailing.included_modules.include?(Mongoid::Document).should be_true
  end
  
  it "should include timestamps" do
    Mailing.included_modules.include?(Mongoid::Timestamps).should be_true
  end

  # FIELDS
  it { should have_field(:date, :type => DateTime) }
  
  # ASSOCIATIONS
  it { should be_referenced_in(:contact) }
  it { should be_referenced_in(:trip) }
  it { should be_referenced_in(:user) }
end
