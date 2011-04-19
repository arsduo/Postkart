class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # devise:
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :trackable, :rememberable

  # FIELDS
  field :name
  field :pic
  field :accepted_terms, :type => Boolean
  
  # EMBEDS AND RELATIONSHIPS
  embeds_many :remote_accounts
  references_many :contacts, :index => true
  references_many :trips, :index => true
  references_many :mailings, :index => true
  
  # INDICES
  index "remote_account.identifier", :unique => true
  
  def self.find_or_create_from_google_token(token)
    google = APIManager::Google.new(token)
    info = google.user_info
    # if we don't have an existing user, make one
    if user = User.limit(1).where("remote_accounts.identifier" => info[:id]).first
      # since we have all the data, might as well update
      user.name = info[:name]
      user.pic = info[:pic]
    else
      # new user
      user = User.new(:name => info[:name], :pic => info[:pic])
    end

    # now, update the remote account, or create it if it's a new user
    # (the record will never be missing for existing users because we look up on it earlier)
    # more accurately, if the record is missing we'll create a second user account =\
    if !user.new_record? && acct = user.remote_accounts.where("identifier" => info[:id]).first
      # update the token      
      acct.token = token
    else
      # set up its remote account
      acct = RemoteAccount.new(
        :account_type => :google,
        :identifier => info[:id],
        :token => token
      )
      acct.user = user
    end
    
    # try to safely save the user since we need this to be saved
    user.safely.save
    
    # warn about errors
    unless user.valid?
      Rails.logger.warn("User w/ #{user.remote_accounts.count} invalid: #{user.errors.inspect}")
      user.remote_accounts.each do |r| 
        Rails.logger.warn("Remote account invalid: #{r.errors.inspect}") unless r.valid?
      end
    end
    
    # now return the user
    user
  end
    
  def populate_google_contacts
    contact_info = google_api.user_contacts

    # fetch all contacts at once, so we can work off local copies
    # convert the user's existing contacts to a hash
    contact_records = self.contacts.to_a.inject({}) {|hash, c| hash[c.remote_id.to_s] = c; hash}

    # buckets for our addresses
    # used to show results later
    new_with_address = []
    new_without_address = []
    updated = []
    # if there's no id, email, or name/address, we can't work with it
    unimportable = []
    
    contact_info.delete_if {|c| c.blank?}.each do |c|
      id_for_contact = Contact.generate_remote_id(c)
      if existing_contact = contact_records[id_for_contact.to_s]
        # update the existing contact
        had_address = existing_contact.addresses.blank?
        existing_contact.update_from_remote_contact(c)
        (had_address ? updated : new_with_address) << existing_contact
      else
        # create a new contact if it's importable
        if id_for_contact
          contact = Contact.new_from_remote_contact(c)
          self.contacts << contact
          contact.save
          (contact.addresses.length > 0 ? new_with_address : new_without_address) << contact
        else
          unimportable << c
        end
      end
    end
        
    # return the new contacts in buckets
    {
      :new_with_address => new_with_address, 
      :new_without_address => new_without_address,
      :updated => updated,
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


