PK ?= {}

# define our local storage wrapper
PK.UserData = do ($) ->
  # we want to load our data from the local storage if possible
  userKey = "user"
  contactsKey = "contacts"
  timestampKey = "mostRecentUpdate"
  contactsByNameKey = "contactsByName"
  tripsByDateKey = "tripsByDate"
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
    !loadingNewData && !!userdata.user

  whenAvailable = (fn) ->
    if isDataAvailable() then fn() else $("body").bind(userLoadSuccessEvent, fn)

  isDataStale = () ->
    isStale

  flush = () ->
    # clear all stored user data
    # for instance, when a user logs out
    store.clear()
    delete userdata.user
    delete userdata.contacts
    delete userdata.contactsByName
    delete userdata.trips
    delete userdata.tripsByDate
    mostRecentUpdate = null
    loadingNewData = false

  # this requires some explanation:
  # we store only the contacts ordered by name, rather than a hash key'd by ID
  # this is more compact, and also avoids needing to sort by name (if we'd only stored the hash)
  # we can't store both, since then it would take 2x memory after load from localStorage
  # (since localStorage's string storage loses the fact the objects are shared)
  buildDictionary = (items = []) ->
    # use the ByName array to create a dictionary of contacts
    # which we need to identify contacts for trips, recs, etc.
    # anywhere where we're not just listing out contacts
    # TODO consider whether we can run this just for updates, and how to fit that in
    dictionary = {}
    for item in items
      id = item._id
      dictionary[id] = item    
    dictionary
  
  updateAndSort = (originalList = [], itemDictionary = {}, updates = [], key) ->
    newItems = []
    if itemDictionary
      # if we have existing items loaded, then 
      # we need to separate out the new items from the updated ones
      # since items come down as an array of both new records and updates
      newItems = []
      for item in updates
        if entry = itemDictionary[item._id]
          # we have a match!
          $.extend(entry, item)
        else
          newItems.push(item)
  
      # now, we know which records are new, and have updated any old ones
      # so add the new ones to the contact list, sorted by last name
      originalList.concat(newItems).sort((i1, i2) -> if i1[key] < i2[key] then -1 else 1)                  
    else
      # we didn't have any previously loaded, so just import the new stuff whole
      updates
  
  storeUser = (results) ->
    if user = results.user
      # load the user, his/her contacts, and update the timestamps
      userdata.user = user

      # we incrementally update users and trips, since we only send down changed records
      # trips are sorted by date
      tripsByDate = userdata.tripsByDate = updateAndSort(userdata.tripsByDate, userdata.trips, results.tripsByDate, "created_at")
      userdata.trips = buildDictionary(tripsByDate)

      contactsByName = userdata.contactsByName = updateAndSort(userdata.contactsByName, userdata.contacts, results.contactsByName, "last_name")
      # now, finally, assemble/update the contact dictionary
      userdata.contacts = buildDictionary(contactsByName)  

      mostRecentUpdate = results.mostRecentUpdate

      # store the data to local storage
      store.set(userKey, user)
      store.set(contactsByNameKey, contactsByName)
      store.set(tripsByDateKey, tripsByDate)
      store.set(timestampKey, mostRecentUpdate)
    
      # loading is done!
      isStale = false
      loadingNewData = false
      userDataIsAvailable()
    else
      error(null, results.error)
  
  cardSent = (trip, contact) -> 
    # add the recipient to the trip and store it
    trip.recipients.push(contact._id)
    store.set(tripsByDateKey, userdata.tripsByDate)
  
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
      params:
        since: mostRecentUpdate
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
      
      tripsByDate = userdata.tripsByDate ?= store.get(tripsByDateKey)
      userdata.trips = buildDictionary(tripsByDate)
      
      contactsByName = userdata.contactsByName ?= store.get(contactsByNameKey)
      userdata.contacts = buildDictionary(contactsByName)
      
      mostRecentUpdate ?= store.get(timestampKey)      
      
      # assume data is stale
      # if not, it'll be automatically cleared in userDataIsAvailable
      isStale = true
    
    # -1, triggered by params[:reloadContacts]=[anything] forces a reload of contact data
    if remoteUpdateTime != -1 && (mostRecentUpdate && mostRecentUpdate >= remoteUpdateTime)
      # local data is fresh, so go with what's already loaded
      userDataIsAvailable()
    else
      # get updated data from the server (if possible)
      # flushing the existing data if told to reload
      userdata.flush() if remoteUpdateTime == -1
      loadDataFromServer()
  
  userdata =
    loadUserData: loadUserData
    isDataAvailable: isDataAvailable
    isDataStale: isDataStale
    whenAvailable: whenAvailable
    userLoadStartEvent: userLoadStartEvent
    userLoadSuccessEvent: userLoadSuccessEvent 
    userLoadFailedEvent: userLoadFailedEvent
    flush: flush
    cardSent: cardSent
    
