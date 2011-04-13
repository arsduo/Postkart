User.blueprint {
  name { "Alex#{sn}" }
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
  first_name { "Alex" }
  last_name { "Koppel" }
  pic { "http://#{sn}" }
  addresses { ["123#{sn} Main St., City, State, USA", "ABCstr #{sn}, Munich, Germany"]}
  remote_id { "REMOTE_ID#{sn}" }
}