class AuthenticationController < ApplicationController
  layout "auth_iframe"
  
  before_filter :ensure_signed_in, :only => :google_populate_contacts
  
  def google_start
    # kick off the process so there's some content while Google is loading
  end
  
  def google_callback
  end
  
  def google_login
    # we have to query Google to find out who the user is before we can do anything
    logger.debug("Making Google request!")
    if token = params[:access_token]
      begin
        @user = User.find_or_create_from_google_token(token)

        # we have a valid token, so clear the flag if set
        session[:retried_invalid_token] = false

        if @user.valid?
          # handle T&C check/update
          @user.update_attribute(:accepted_terms, true) if params[:accepted_terms]      
          sign_in(:user, @user) if @user.accepted_terms
          @result = {:name => @user.name, :isNewUser => (Time.now - @user.created_at) < 30}
          @error = {:needsTerms => true} unless @user.accepted_terms
        else
          @error = {:validation => @user.errors}
        end

      # error handling
      rescue APIManager::Google::InvalidTokenError
        handle_invalid_token_error
      rescue StandardError => err
        send_exception_notification(err)
        @error = {:otherError => true}
      end
    else
      @error = {:noToken => true}
      logger.warn("Error! No token received!")
    end
    
    render :json => (@result || {}).merge(:error => @error)
  end
  
  def google_populate_contacts
    begin
      contact_groups = current_user.populate_google_contacts 
      @result = contact_groups.inject({}) {|result, data| result[data.first.to_s.titleize] = data.last.length; result}
    rescue APIManager::Google::InvalidTokenError
      handle_invalid_token_error
    rescue StandardError => err
      send_exception_notification(err)
      @error = {:otherError => true}
    end
    render :json => (@result || {}).merge(:error => @error)
  end
  
  private 
    
  def ensure_signed_in    
    render :json => {:error => {:loginRequired => true}} unless user_signed_in?
  end
  
  # invalid tokens
  
  @@invalid_tokens = 0
  @@invalid_token_error_sent = false  
  def handle_invalid_token_error
    @error = {:invalidToken => true}
    # if it's an invalid token, retry the whole process once
    # but don't send them on an infinite loop
    unless session[:retried_invalid_token]
      session[:retried_invalid_token] = true
      @error[:retry] = true
    else
      # we've tried twice and it's still not working
      # something might be fundamentally wrong
      @@invalid_tokens += 1
      if @@invalid_tokens >= 5 && !@@invalid_token_error_sent
        begin 
          raise APIManager::Google::InvalidTokenError, "More than 5 invalid tokens in one sitting!"
        rescue APIManager::Google::InvalidTokenError => err
          @@invalid_token_error_sent = true
          send_exception_notification(err)
        end
      end
    end
  end

end
