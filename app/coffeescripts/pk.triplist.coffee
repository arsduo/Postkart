PK ?= {}

# define a handler for Trip management
PK.TripList = do ($) ->
  init = (id) ->
    if PK.UserData.isDataAvailable() 
      elem = $(id)
      elem.html(PK.render("trip_list", {trips: PK.UserData.tripsByDate}))
      elem.closest(":jqmData(role='page')").page().page("enhance") if PK.mobile
    else
      $("body").bind(PK.UserData.userLoadSuccessEvent, () -> init(id))
  
  {
    init: init 
  }
