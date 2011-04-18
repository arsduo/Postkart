module ContactsTestHelper
  
  @@counter = 0
  
  def sample_portable_contact
    @@counter += 1
    
    parsed_contact = {
      :first_name => "Alex#{@@counter}",
      :last_name => "Lastname#{@@counter}",
      :name => "Alex Lastname#{@@counter}",
      :email => "sample#{@@counter}@sample.com",
      :addresses => ["addr#{@@counter}", "addr#{@@counter}_2"],
      :id => "id#{@@counter}",
      :pic => "http://pic/#{@@counter}",
      :account_type => :google
    }
    
    # the mock response from PortableContacts
    raw_portable_contact = {
      "name" => {
        "givenName" => parsed_contact[:first_name], 
        "familyName" => parsed_contact[:last_name], 
        "formatted" => "fullname"
      },
      "displayName" => parsed_contact[:name], 
      "urls" => [{"type" => "profile", "value" => "url"}], 
      "addresses" => [
        {"type" => "currentLocation", "streetAddress" => "addr", "formatted" => parsed_contact[:addresses].first},
        {"type" => "currentLocation", "streetAddress" => "addr3", "formatted" => parsed_contact[:addresses].last}
      ], 
      "id" => parsed_contact[:id], 
      "thumbnailUrl" => parsed_contact[:pic],
      "emails" => [
        {"value" => "anotherEmail"},
        {"primary" => true, "value" => parsed_contact[:email]},
        {"type" => "other", "value" => "yetAnotherEmail"},
        {"type" => "other", "value" => "evenMoreEmail"}
      ], 
      "isViewer" => true,   
      "profileUrl" => "profileurl"
    }
    
    [parsed_contact, raw_portable_contact]    
  end
  
  def hashes_and_contacts(count = 10, user = nil)
    # creates contacts using Machinist
    # and hashes to match
    count.times.inject([]) do |hashes, i|
      contact = Contact.make(:user => user)
      hash_for_contact = {
        :first_name => contact.first_name,
        :last_name => contact.last_name,
        :name => contact.name,
        # don't have to worry about email, since c has a remote_id
        :email => "sample#{@@counter}@sample.com",
        :addresses => contact.addresses,
        :id => contact.remote_id,
        :pic => contact.pic,
        :account_type => :google
      }
      hashes << [hash_for_contact, contact]
    end
  end
end