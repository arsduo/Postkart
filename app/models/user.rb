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
  
  def self.find_or_create_from_google_token(token)
    google = APIManager::Google.new(token)
    info = google.user_info
    # if we don't have an existing user, make one
    unless user = User.limit(1).where("remote_accounts.identifier" => info[:identifier]).first
      # new user
      user = User.new(:name => info[:name])
    end

    # now, update the remote account, or create it if it's a new user or the record is missing
    if !user.new_record? && remote_account = user.remote_accounts.where("remote_accounts.identifier" => info[:identifier]).first
      # update the token      
      remote_account.token = token
    else
      # set up its remote account
      acct = RemoteAccount.new(
        :account_type => :google,
        :identifier => info[:identifier],
        :token => token
      )
      user.remote_accounts << acct
    end
    user.save
    
    # now return the user
    user
  end
  
  def populate_google_contacts
    contacts = google_api.user_contacts

    # buckets for our addresses
    # used to show results later
    regular = []
    no_address = []
    # if there's no id, email, or name/address, we can't work with it
    unimportable = []
    
    contacts.each do |c|
      id_for_contact = Recipient.generate_remote_id(c)
      unless existing_contact = self.recipients.where(:remote_id => id_for_contact).first
        # create a new recipient
        r = Recipient.new_from_remote_contact(c)
        if r.id
          self.recipients << r
          (r.addresses.length > 0 ? regular : no_address) << r
        else
          unimportable << r
        end
      else
        # update the existing contact
        existing_contact.update_from_remote_contact(c)
      end
    end
  end
  
  def google_api
    unless @google_api 
      if google_account = self.remote_accounts.where(:account_type => :google).first
        @google_api = APIManager::Google.new(google_account.token)
      end
    end
    @google_api
  end
end
