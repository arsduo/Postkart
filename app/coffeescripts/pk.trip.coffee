PK ?= {}

# define our local storage wrapper
PK.Trip = do ($) ->
  trip = null
  
  renderList = () ->
    recipients = trip.recipients
    listHTML = for contact in (PK.UserData.contactsByName || [])
      JST.trip_contact({contact: contact}) unless contact in trip.recipients
      
    if listHTML.length > 0
      $("#contacts").html(listHTML.join(""))
    else
      $("#contacts").html(JST.trip_no_contacts())
    
    contactDictionary = PK.UserData.contacts
    recipientHTML = for recipient in recipients
      JST.trip_recipient({contact: r}) if r = contactDictionary[recipient]      
    
    if recipientHTML.length > 0
      $("#recipients").html(recipientHTML.join(""))
    else
      $("#recipients").html(JST.trip_no_contacts())
  
  init = (tripInfo) ->
    # immediately render the trip name, etc.
    trip = tripInfo
    $("#tripName").html(tripInfo.location_name)
    $("body").bind(PK.UserData.userLoadSuccessEvent, renderList)

  {
    init: init
  }