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

