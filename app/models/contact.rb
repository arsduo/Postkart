class Contact
  include Mongoid::Document
  include Mongoid::Timestamps
  

  # FIELDS
  field :first_name
  field :last_name
  field :name
  field :addresses, :type => Array, :default => []
  field :remote_id

  # not being used for now, but for future reference
  field :city
  field :state
  field :country
  
  # EMBEDS AND RELATIONSHIPS
  referenced_in :user, :inverse_of => :contacts
  references_many :mailings, :index => true

  # INDICES
  index [:user, :remote_id], :unique => true
  index [:user, [:last_name, Mongo::ASCENDING]]
  
  # VALIDATION
  validates :remote_id, :presence => true
  
  def update_from_remote_contact(contact_hash)
    self.first_name = contact_hash[:first_name]
    self.last_name = contact_hash[:last_name]
    self.name = contact_hash[:name]
    self.addresses = contact_hash[:addresses]
    self.remote_id = Contact.generate_remote_id(contact_hash)
    self.save
  end
  
  def self.new_from_remote_contact(contact_hash)
    # not every Google contact will have a remote ID, but we just have to live with that
    Contact.new({
      :first_name => contact_hash[:first_name],
      :last_name => contact_hash[:last_name],
      :name => contact_hash[:name],
      :addresses => contact_hash[:addresses],
      :remote_id => generate_remote_id(contact_hash)
    })
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
    elsif (name = contact_hash[:name]) && address = contact_hash[:addresses].first
      Digest::MD5.hexdigest(name + address)
    end
  end
end
