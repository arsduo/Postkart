PK ?= {}

# define a handler for Trip management
PK.TripList = do ($) ->
  init = (id) ->
    if PK.UserData.isDataAvailable() 
      $(id).html(PK.render("trip_list", {trips: PK.UserData.tripsByDate}))
      $.mobile.reenhance() if PK.mobile
    else
      $("body").bind(PK.UserData.userLoadSuccessEvent, () -> init(id))
  
  {
    init: init 
  }
