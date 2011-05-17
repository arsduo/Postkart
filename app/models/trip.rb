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
  # this is an array of user IDs, a denormalization of mailings
  # unlike with users and contacts, we often need to query for all trips + contacts
  # and this saves us some time in the join
  # see http://www.mongodb.org/display/DOCS/MongoDB+Data+Modeling+and+Rails
  field :recipients,  :type => Array

  # associations
  referenced_in   :user, :inverse_of => :trips
  references_many :mailings
  
  # INDEX
  index [:user, :status]
  
  # validations
  validates :location_name, :description, :start_date, :presence => true
  validates :status, :inclusion => { :in => Trip::STATUSES }
  
  # scopes
  scope :active, :where => {:status => :active}
  scope :done, :where => {:status => :done}

  def client_json
    # JSON sent down to the client for storage
    self.as_json(:only => [:_id, :description, :status, :recipients]).merge("created_at" => self.created_at.to_i)
  end
end
