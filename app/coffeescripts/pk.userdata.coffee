PK ?= {}

# define our local storage wrapper
PK.UserData = do ($) ->
  # we want to load our data from the local storage if possible
  userKey = "user"
  contactsKey = "contacts"
  timestampKey = "mostRecentUpdate"
  loadingNewData = false
  mostRecentUpdate = null
  
  # events
  userLoadStartEvent = "startedUserLoad.pk"
  userLoadSuccessEvent = "successfulUserLoad.pk"
  userLoadFailedEvent = "failedUserLoad.pk"
  
  isUserDataAvailable = () ->
    # we use the stored time (= most recent update for this user) as a proxy
    # for whether data has been stored in localStorage
    # this fn is useful to have around, even though it's mostly used in testing ATM
    !loadingNewData && !!(userdata.user || store.get(userKey))

  flush = () ->
    # clear all stored user data
    # for instance, when a user logs out
    store.clear()
    delete userdata.user
    delete userdata.contacts
    mostRecentUpdate = null

  storeUser = (results) ->
    if user = results.user
      # load the user, his/her contacts, and update the timestamps
      userdata.user = user
      contacts = userdata.contacts = results.contacts
      mostRecentUpdate = results.mostRecentUpdate

      # store the data to local storage
      store.set(userKey, user)
      store.set(contactsKey, contacts)
      store.set(timestampKey, mostRecentUpdate)

      # loading is done!
      loadingNewData = false
      userDataIsAvailable()
    else
      error(null, results.error)
    
  userDataIsAvailable = () ->
    # fire a custom jQuery event on the body
    $("body").trigger(userLoadSuccessEvent)
    
  error = (jQevent, errorData) ->
    $("body").trigger(userLoadFailedEvent, errorData)
    # reset loading new data, so that we can make use of any cached data
    # we don't trigger the userDataIsAvailable event, though
    # it's up to the client to respond to the error by using stale data
    loadingNewData = false

  loadDataFromServer = () ->
    # we have to load data from the server
    # first, prevent the system from using local data
    loadingNewData = true
    $("body").trigger(userLoadStartEvent)
    $.ajax({
      url: "/home/user_data",
      method: "get",
      success: storeUser,
      error: error
    })
  
  loadUserData = (remoteUpdateTime) ->
    # if loaded data is available for this user, use that
    # else, load from the server
    if user = store.get(userKey)
      # we have data for this user, so load it
      # always load local data if available
      # so we can use something even if the call fails
      userdata.user = user
      userdata.contacts ?= store.get(contactsKey)
      mostRecentUpdate ?= store.get(timestampKey)      
    
    if mostRecentUpdate && mostRecentUpdate >= remoteUpdateTime
      # local data is fresh, so go with what's already loaded
      userDataIsAvailable()
    else
      # get updated data from the server (if possible)
      loadDataFromServer()
    
  userdata =
    loadUserData: loadUserData
    isUserDataAvailable: isUserDataAvailable
    userLoadStartEvent: userLoadStartEvent
    userLoadSuccessEvent: userLoadSuccessEvent 
    userLoadFailedEvent: userLoadFailedEvent
    flush: flush
    
