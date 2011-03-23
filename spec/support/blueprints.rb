User.blueprint {
  name { "Alex#{sn}" }
  remote_accounts { [RemoteAccount.make] }
}

RemoteAccount.blueprint {
  account_type { :google }
  identifier { "identifier#{sn}" }
  email { "email#{sn}" }
}

