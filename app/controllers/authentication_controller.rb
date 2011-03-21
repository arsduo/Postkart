class AuthenticationController < ApplicationController
  def google_callback
  end
  
  def google_login
    # annoyingly, we have to query Google to find out who the user is before we can do anything
    logger.debug("Making Google request!")
    token = params[:access_token]
    @user_info = APIManager::Google.new(token).user_info
    logger.debug "Got result!\n#{@user_info.inspect}"
    # now find or create the user
    if user = User.where("remote_accounts.identifier" => @user_info[:identifier]).limit(1).first
      logger.debug("Found user #{user.inspect}")
      remote_account = user.remote_accounts.where(:identifier => @user_info[:identifier]).first
      remote_account.token = token
      remote_account.save
    else
      # register the user
      user = User.new(
        :name => @user_info[:name]
      )
      user.remote_accounts << RemoteAccount.new(
        :account_type => :google,
        :identifier => @user_info[:email],
        :token => token
      )
      user.save
      logger.debug("Created user: #{user.inspect}")
    end
    
    sign_in(:user, user)
  end

end
