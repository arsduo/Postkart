class Mailing
  include Mongoid::Document
  include Mongoid::Timestamps

  # EMBEDDED
  embedded_in :trip, :inverse_of => :mailings
  
  # FIELDS
  field :date, :type => DateTime
  
  # ASSOCIATIONS
  referenced_in :recipient, :inverse_of => :mailings
  referenced_in :user, :inverse_of => :mailings
end
