class RemoteAccount
  include Mongoid::Document
  include Mongoid::Timestamps

  # constants
  TYPES = [
    :google
  ]
  
  # EMBEDDED
  embedded_in :user, :inverse_of => :remote_accounts
  
  # FIELDS
  field :account_type, :type => Symbol
  field :identifier
  field :token
  
  # validation
  validates :account_type, :presence => true, :inclusion => { :in => TYPES }
  validates :identifier, :presence => true
end