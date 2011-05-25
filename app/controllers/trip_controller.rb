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
        
        @result = true
      end
    end
    render :json => {:result => @result}
  end

end
