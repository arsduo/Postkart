class TripController < ApplicationController
  def create
    if current_user && location = params[:trip][:location_name]
      @trip = Trip.new(
        :location_name => location,
        :description => location,
        :start_date => Time.now,
        :status => :active,
        :user => current_user
      )
      
      @trip.save
    end
    redirect_to root_url
  end

  def view
    if current_user && @trip = Trip.where(:_id => params[:id]).first
      # fetch this to a variable so we don't have to make two trips to the db
      @mailings = @trip.mailings
    else
      redirect_to root_url
    end    
  end
  
  def send_card 
    if current_user
      # needs to ensure there aren't duplicate mailings?
      trip = Trip.where(:_id => params[:trip_id]).first
      contact = current_user.contacts.where(:_id => params[:contact_id]).first
      if trip && contact
        mailing = Mailing.create(
          :contact => contact,
          :trip => trip,
          :user => current_user,
          :date => Time.now
        )
      end
    end    
    redirect_to :action => :view, :id => params[:trip_id] and return
  end

end