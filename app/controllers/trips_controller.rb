class TripsController < ApplicationController
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
      @mailing_recipients = @trip.mailings.collect {|m| m.contact}
      # broken!
      logger.debug("There? #{@contacts.include? @mailing_recipients.first}")
      @contacts = current_user.contacts.asc(:last_name).delete_if {|c| @mailing_recipients.include?(c)}
      logger.debug("There? #{@contacts.include? @mailing_recipients.first}")
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
