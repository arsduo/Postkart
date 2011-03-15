require 'spec_helper'

describe Trip do
  # modules
  it "should be a Mongoid document" do
    Trip.included_modules.include?(Mongoid::Document).should be_true
  end
  
  it "should include timestamps" do
    Trip.included_modules.include?(Mongoid::Timestamps).should be_true
  end
  
  # fields
  it { should have_field(:location_name) }
  it { should have_field(:description) }
  it { should have_field(:start_date) }
  it { should have_field(:end_date) }
  it { should have_field(:status, :type => Symbol) }
  
  # associations
  it { should be_referenced_in(:user) }
  it { should embed_many(:mailings) }
  
  # validations
  it { should validate_presence_of(:location_name) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:start_date) }  
  it { should validate_inclusion_of(:status, :in => Trip::STATUSES) }

  
end
