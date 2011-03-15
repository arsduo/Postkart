class Trip
  include Mongoid::Document
  include Mongoid::Timestamps
  
  # constants
  STATUSES = [
    # on the trip, or it's coming up, or there are cards remaining
    :active,
    # the trip is done
    :done     
  ]

  # FIELDS
  field :location_name
  field :description
  field :start_date
  field :end_date
  field :status, :type => Symbol

  # associations
  referenced_in :user, :inverse_of => :trips
  embeds_many :mailings
  
  # INDEX
  index [:user, :status]
  
  # validations
  validates :location_name, :description, :start_date, :presence => true
  validates :status, :inclusion => { :in => Trip::STATUSES }
  
  # scopes
  scope :active, :where => {:status => :active}
  scope :done, :where => {:status => :done}


end
