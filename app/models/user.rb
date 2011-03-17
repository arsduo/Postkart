class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # devise:
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :trackable, :registerable, :token_authenticatable, :omniauthable, :rememberable

  # FIELDS
  field :google_id
  field :google_token
  
  # EMBEDS AND RELATIONSHIPS
  references_many :recipients, :index => true
  references_many :trips, :index => true
  references_many :mailings, :index => true
  
  # INDICES
  index :google_id
  
  # VALIDATION
  validates_presence_of :google_id
  
end
