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
    unless user = User.limit(1).where("remote_accounts.remote_id" => info[:id]).first
      # new user
      user = User.new(:name => info[:name])
    end

    # now, update the remote account, or create it if it's a new user
    # (the record will never be missing for existing users because we look up on it earlier)
    # more accurately, if the record is missing we'll create a second user account =\
    if !user.new_record? && acct = user.remote_accounts.where("remote_accounts.remote_id" => info[:id]).first
      # update the token      
      acct.update_attribute(:token, token)
    else
      # set up its remote account
      acct = RemoteAccount.new(
        :account_type => :google,
        :remote_id => info[:id],
        :token => token
      )
      user.remote_accounts << acct
    end
    user.save # also saves the account
    
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
        if r.remote_id
          self.recipients << r
          r.save
          (r.addresses.length > 0 ? regular : no_address) << r
        else
          unimportable << r
        end
      else
        # update the existing contact
        existing_contact.update_from_remote_contact(c)
        (existing_contact.addresses.length > 0 ? regular : no_address) << existing_contact
      end
    end
        
    # return the new contacts in buckets
    {
      :updated_with_address => regular, 
      :updated_without_address => no_address,
      :unimportable => unimportable
    }
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
