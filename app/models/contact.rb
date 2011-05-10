class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  

  # FIELDS
  field :first_name
  field :last_name
  field :name
  field :encrypted_addresses, :type => Array, :default => []
  field :pic
  field :remote_id
  
  # EMBEDS AND RELATIONSHIPS
  referenced_in :user, :inverse_of => :contacts
  references_many :mailings, :index => true

  # INDICES
  index [:user, :remote_id], :unique => true
  index [:user, [:last_name, Mongo::ASCENDING]]
  
  # VALIDATION
  validates :remote_id, :presence => true
  
  def client_json
    # JSON sent down to the client for storage
    self.as_json :only => [:_id, :name], :methods => :addresses
  end
  
  def addresses
    # decrypt addresses
    self.encrypted_addresses.map {|addr| Blowfish.decrypt(ENCRYPTION_KEY, addr.to_s)}
  end
  
  def addresses=(new_addresses)
    # decrypt addresses
    # since encryption generates non-UTF strings, we have to wrap it in BSON::Binary
    self.encrypted_addresses = (new_addresses || []).map do |addr|
      # shorten USA
      addr2 = addr.gsub(/United States( of America)*/i, "USA")
      BSON::Binary.new(Blowfish.encrypt(ENCRYPTION_KEY, addr2))
    end
  end
  

  def update_from_remote_contact(contact_hash)
    self.first_name = contact_hash[:first_name]
    self.last_name = contact_hash[:last_name]
    self.name = contact_hash[:name]
    self.pic = contact_hash[:pic]
    self.addresses = contact_hash[:addresses]
    self.remote_id = Contact.generate_remote_id(contact_hash)
    self.save
  end
  
  def self.new_from_remote_contact(contact_hash)
    # not every Google contact will have a remote ID, but we just have to live with that
    contact = Contact.new({
      :first_name => contact_hash[:first_name],
      :last_name => contact_hash[:last_name],
      :name => contact_hash[:name],
      :pic => contact_hash[:pic],
      :remote_id => generate_remote_id(contact_hash)
    })
    # encrypt addresses
    contact.addresses = contact_hash[:addresses]
    contact
  end
  
  def self.generate_remote_id(contact_hash)
    # we need a remote ID for updating records later
    # so we use the remote ID if given
    # if not, we hash the email if provided
    # and if that fails, we hash the name + address
    # if nothing, just give up
    if id = contact_hash[:id]
      id
    elsif email = contact_hash[:email]
      Digest::MD5.hexdigest(email)
    elsif (name = contact_hash[:name]) && address = (contact_hash[:addresses] || []).first
      Digest::MD5.hexdigest(name + address)
    end
  end
end
