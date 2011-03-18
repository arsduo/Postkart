class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # devise:
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :trackable, :rememberable

  # FIELDS
  field :name
  
  # EMBEDS AND RELATIONSHIPS
  embeds_many :remote_accounts
  references_many :recipients, :index => true
  references_many :trips, :index => true
  references_many :mailings, :index => true
  
  # INDICES
  index "remote_account.identifier", :unique => true
end
