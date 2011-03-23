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
  
  def self.from_google_token(token)
    google = APIManager::Google.new(token)
    info = google.user_info
    # if we don't have an existing user, make one
    if user = User.limit(1).where("remote_accounts.identifier" => info[:identifier]).first
      # update the token
      remote_account = user.remote_accounts.where("remote_accounts.identifier" => info[:identifier]).first
      remote_account.token = token
      remote_account.save
    else
      # new user
      user = User.new(:name => info[:name])
      # set up its remote account
      acct = RemoteAccount.new(
        :type => :google,
        :identifier => info[:identifier],
        :token => token
      )
      user.remote_accounts << acct
      user.save
    end
    
    # now return the user
    user
  end
end
