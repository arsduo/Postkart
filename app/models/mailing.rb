class Mailing
  include Mongoid::Document
  include Mongoid::Timestamps

  # FIELDS
  field :date, :type => DateTime
  
  # ASSOCIATIONS
  referenced_in :contact, :inverse_of => :mailings
  referenced_in :trip, :inverse_of => :mailings
  referenced_in :user, :inverse_of => :mailings
end
