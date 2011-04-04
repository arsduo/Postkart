User.blueprint {
  name { "Alex#{sn}" }
  remote_accounts { [RemoteAccount.make] }
  created_at { Time.now }
  updated_at { Time.now }
}

RemoteAccount.blueprint {
  account_type { :google }
  identifier { "identifier#{sn}" }
  email { "email#{sn}" }
  token { "token#{sn}" }
}

Recipient.blueprint {
  first_name { "Alex" }
  last_name { "Koppel" }
  addresses { ["123#{sn} Main St., City, State, USA", "ABCstr #{sn}, Munich, Germany"]}
  remote_id { "REMOTE_ID#{sn}" }
}