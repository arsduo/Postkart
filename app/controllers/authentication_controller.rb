class AuthenticationController < ApplicationController
  layout "minimal"
  
  def google_callback
  end
  
  def google_login
    # annoyingly, we have to query Google to find out who the user is before we can do anything
    logger.debug("Making Google request!")
    if (token = params[:access_token])
      user = User.find_or_create_from_google_token(token)

      # handle T&C check/update
      user.update_attribute(:accepted_terms, true) if params[:acceptedTerms]      
      sign_in(:user, user) 
      if user.accepted_terms
        sign_in(:user, user) 
        sign_in(:user, user, :bypass => true)
      end
      render :json => {:name => user.name, :si => user_signed_in?, :is_new_user => (Time.now - user.created_at) < 30, :needs_terms => !user.accepted_terms}
    else
      render :json => {:no_token => true}
    end
  end
  
  def google_populate_contacts
    render :json => {} and return
    if user_signed_in?
      contact_groups = current_user.populate_google_contacts
      render :json => contact_groups.inject({}) {|result, data| result[data.first] = data.last.length; result}
    else
      logger.debug("Not signed in!")
      render :json => {:loginRequired => true}
    end
  end

end
