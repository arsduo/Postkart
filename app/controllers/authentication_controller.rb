class AuthenticationController < ApplicationController
  def google_callback
  end
  
  def google_login
    # annoyingly, we have to query Google to find out who the user is before we can do anything
    logger.debug("Making Google request!")
    @user_info = APIManager::Google.new(params[:access_token]).user_info
    logger.debug "Got result!\n#{@user_info.inspect}"
    # now find or create the user
  end

end
