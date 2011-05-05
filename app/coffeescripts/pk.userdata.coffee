PK ?= {}

# define our local storage wrapper
PK.UserData = do ($) ->
  # we want to load our data from the local storage if possible
  userKey = "user"
  contactsKey = "contacts"
  timestampKey = "mostRecentUpdate"
  contactsByNameKey = "contactsByName"
  loadingNewData = false
  mostRecentUpdate = null
  isStale = false
  
  # events
  userLoadStartEvent = "startedUserLoad.pk"
  userLoadSuccessEvent = "successfulUserLoad.pk"
  userLoadFailedEvent = "failedUserLoad.pk"
  
  isDataAvailable = () ->
    # we use the stored time (= most recent update for this user) as a proxy
    # for whether data has been stored in localStorage
    # this fn is useful to have around, even though it's mostly used in testing ATM
    !loadingNewData && !!(userdata.user || store.get(userKey))

  isDataStale = () ->
    isStale

  flush = () ->
    # clear all stored user data
    # for instance, when a user logs out
    store.clear()
    delete userdata.user
    delete userdata.contacts
    delete userdata.contactsByName
    mostRecentUpdate = null

  # this requires some explanation:
  # we store only the contacts ordered by name, rather than a hash key'd by ID
  # this is more compact, and also avoids needing to sort by name (if we'd only stored the hash)
  # we can't store both, since then it would take 2x memory after load from localStorage
  # (since localStorage's string storage loses the fact the objects are shared)
  buildContactDictionary = (contactsByName) ->
    # use the ByName array to create a dictionary of contacts
    # which we need to identify contacts for trips, recs, etc.
    # anywhere where we're not just listing out contacts
    contactDictionary = {}
    for contact in contactsByName
      id = contact._id
      contactDictionary[id] = contact    
    userdata.contacts = contactDictionary

  storeUser = (results) ->
    if user = results.user
      # load the user, his/her contacts, and update the timestamps
      userdata.user = user
      contactsByName = userdata.contactsByName = results.contactsByName
      mostRecentUpdate = results.mostRecentUpdate      
      buildContactDictionary(contactsByName)

      # store the data to local storage
      store.set(userKey, user)
      store.set(contactsByNameKey, contactsByName)
      store.set(timestampKey, mostRecentUpdate)
      
      # loading is done!
      isStale = false
      loadingNewData = false
      userDataIsAvailable()
    else
      error(null, results.error)
    
  userDataIsAvailable = () ->
    # fire a custom jQuery event on the body
    $("body").trigger(userLoadSuccessEvent)
    
  error = (jQevent, errorData) ->
    $("body").trigger(userLoadFailedEvent, errorData)
    # if we have stale data, announce it so we can make use of any cached data
    # it's up to the client to check the stale state and respond appropriately
    loadingNewData = false
    userDataIsAvailable() if isDataAvailable()
    

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
      contactsByName = userdata.contactsByName ?= store.get(contactsByNameKey)
      mostRecentUpdate ?= store.get(timestampKey)      
      buildContactDictionary(contactsByName)
      # assume data is stale
      # if not, it'll be automatically cleared in userDataIsAvailable
      isStale = true
      
    if mostRecentUpdate && mostRecentUpdate >= remoteUpdateTime
      # local data is fresh, so go with what's already loaded
      userDataIsAvailable()
    else
      # get updated data from the server (if possible)
      loadDataFromServer()
  
  userdata =
    loadUserData: loadUserData
    isDataAvailable: isDataAvailable
    isDataStale: isDataStale
    userLoadStartEvent: userLoadStartEvent
    userLoadSuccessEvent: userLoadSuccessEvent 
    userLoadFailedEvent: userLoadFailedEvent
    flush: flush
    
