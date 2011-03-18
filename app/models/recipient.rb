class Recipient
  include Mongoid::Document
  include Mongoid::Timestamps
  

  # FIELDS
  field :first_name
  field :last_name
  field :addr_encrypted
  field :city
  field :state
  field :postal_code
  field :country
  field :remote_id
  
  # EMBEDS AND RELATIONSHIPS
  referenced_in :user, :inverse_of => :recipients
  references_many :mailings, :index => true

  # INDICES
  index :remote_id, :unique => true
  
  # VALIDATION
  validates :remote_id, :presence => true
end
