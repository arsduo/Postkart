class HomeController < ApplicationController
  before_filter :ensure_signed_in, :only => :user_data
  
  def index
  end
  
  def user_data
    last_update = Time.at(params[:since].to_i)
    render :json => {
      :user => current_user.client_json, 
      # the Mongo Ruby driver effectively loads content in batches
      # so unlike with AR this is okay regardless of how large the contact group grows
      :contactsByName => current_user.contacts.where(:updated_at.gte => last_update).asc(:last_name).map {|c| c.client_json},
      :tripsByDate => current_user.trips.where(:updated_at.gte => last_update).asc.map {|t| t.client_json},
      :mostRecentUpdate => current_user.contacts_updated_at.to_i
    }    
  end
end
