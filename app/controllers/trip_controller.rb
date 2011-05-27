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
      
      # update the user so they get updates
      current_user.update_attribute(:trips_updated_at, @trip.updated_at)
    end
    redirect_to root_url
  end

  def view
    redirect_to root_url and return unless current_user && @trip = Trip.where(:_id => params[:id]).first
    @header_text = @trip.description
  end
  
  def send_card 
    @result = false
    if current_user
      # needs to ensure there aren't duplicate mailings?
      logger.debug("Has user")
      trip = Trip.where(:_id => params[:trip_id]).first
      logger.debug("Trip: #{trip}")
      contact = current_user.contacts.where(:_id => params[:contact_id]).first
      logger.debug("Contact: #{contact}")
      if trip && contact
        logger.debug("going!")
        mailing = Mailing.create(
          :contact => contact,
          :trip => trip,
          :user => current_user,
          :date => Time.now
        )
        
        # also store the contact's ID on the trip model
        # so that we have easy reference to it
        # when we send down cached data to the user in HomeController
        trip.recipients << contact._id
        trip.save
        
        # update the user so they get updates
        current_user.update_attribute(:trips_updated_at, trip.updated_at)
        
        
        @result = true
      end
    end
    render :json => {:result => @result}
  end

end
