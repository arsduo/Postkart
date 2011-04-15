class AuthenticationController < ApplicationController
  layout "minimal"
  
  before_filter :ensure_signed_in, :only => :google_populate_contacts
  
  def google_start
    raise Exception, "let's see if this works"
  end
  
  def google_callback
  end
  
  def google_login
    # annoyingly, we have to query Google to find out who the user is before we can do anything
    logger.debug("Making Google request!")
    if (token = params[:access_token])
      user = User.find_or_create_from_google_token(token)

      # handle T&C check/update
      user.update_attribute(:accepted_terms, true) if params[:acceptedTerms]      
      if user.valid?
        sign_in(:user, user) if user.accepted_terms
        render :json => {:name => user.name, :is_new_user => (Time.now - user.created_at) < 30, :needs_terms => !user.accepted_terms}
      else
        render :json => {:error => {:validations => user.errors}}
      end
    else
      render :json => {:error => {:no_token => true}}
      logger.warn("Error! ")
    end
  end
  
  def google_populate_contacts
    contact_groups = current_user.populate_google_contacts
    render :json => contact_groups.inject({}) {|result, data| result[data.first] = data.last.length; result}
  end
  
  private 
    
  def ensure_signed_in
    unless user_signed_in?
      logger.debug("Not signed in!")
      render :json => {:login_required => true}
    end    
  end

end
