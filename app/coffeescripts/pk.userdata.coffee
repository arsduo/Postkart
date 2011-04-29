PK ?= {}

# define our local storage wrapper
PK.UserData = do ($) ->
  # we want to load our data from the local storage if possible
  userKey = "users"
  timestampKey = "mostRecentUpdate"
  loadingNewData = false
  mostRecentUpdateTime = null
  
  # events
  userLoadStartEvent = "startedUserLoad.pk"
  userLoadSuccessEvent = "successfulUserLoad.pk"
  userLoadFailedEvent = "failedUserLoad.pk"
  
  isUserDataAvailable = () ->
    # we use the stored time (= most recent update for this user) as a proxy
    # for whether data has been stored in localStorage
    # this fn is useful to have around, even though it's mostly used in testing ATM
    !loadingNewData && !!(userdata.users || store.get(timestampKey))

  resetState = () ->
    # clear data stored in memory
    # mainly useful for testing
    delete userdata.users
    delete mostRecentUpdate

  storeUsers = (results) ->
    if results.users
      # store the users and update the timestamps
      userdata.users = results.users
      store.set(userKey, results.users)
      mostRecentUpdate = results.mostRecentUpdate
      store.set(timestampKey, mostRecentUpdate)
      # loading is done!
      loadingNewData = false
      userDataIsAvailable()
    else
      error(null, results.error)
    
  userDataIsAvailable = () ->
    # fire a custom jQuery event on the body
    $("body").trigger(userLoadSuccessEvent);
    
  error = (jQevent, errorData) ->
    $("body").trigger(userLoadFailedEvent, errorData);
    # reset loading new data, so that we can make use of any cached data
    # we don't trigger the userDataIsAvailable event, though
    # it's up to the client to respond to the error by using stale data
    loadingNewData = false

  loadDataFromServer = () ->
    # we have to load data from the server
    # first, prevent the system from using local data
    loadingNewData = true
    $("body").trigger(userLoadStartEvent);
    $.ajax({
      url: "/home/user_data",
      method: "get",
      success: storeUsers,
      error: error
    })
  
  loadUserData = (remoteUpdateTime) ->
    # if loaded data is available, use that
    # else, look in the store
    # and if that fails, load from the server
    mostRecentUpdate ?= store.get(timestampKey)

    # always load local data if available, so we can use something
    userdata.users ?= store.get(userKey);
    
    if mostRecentUpdate && mostRecentUpdate >= remoteUpdateTime
      # local data is fresh, so go with what's already loaded
      userDataIsAvailable()
    else
      # get updated data from the server (if possible)
      loadDataFromServer();

  userdata =
    loadUserData: loadUserData
    isUserDataAvailable: isUserDataAvailable
    userLoadStartEvent: userLoadStartEvent
    userLoadSuccessEvent: userLoadSuccessEvent 
    userLoadFailedEvent: userLoadFailedEvent
    resetState: resetState
    
