User.blueprint {
  name { Faker::Name.name }
  pic { "http://#{sn}" }
  remote_accounts { [RemoteAccount.make] }
  accepted_terms { true }
  created_at { Time.now }
  updated_at { Time.now }
}

RemoteAccount.blueprint {
  account_type { :google }
  identifier { "identifier#{sn}" }
  email { "email#{sn}" }
  token { "token#{sn}" }
}

Contact.blueprint {
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  name { Faker::Name.name }
  pic { "http://#{sn}" }
  addresses { ["123#{sn} Main St., City, State, USA", "ABCstr #{sn}, Munich, Germany"]}
  remote_id { "REMOTE_ID#{sn}" }
}