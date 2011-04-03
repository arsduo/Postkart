module PortableContactsTestHelper
  
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
  
end