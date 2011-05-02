class HomeController < ApplicationController
  before_filter :ensure_signed_in, :only => :user_data
  
  def index
  end
  
  def user_data
    render :json => {:user => current_user, :contacts => current_user.contacts, :mostRecentUpdate => current_user.contacts_updated_at.to_i}    
  end
end
