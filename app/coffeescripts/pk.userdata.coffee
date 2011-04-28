PK ?= {}

# define our local storage wrapper
PK.UserData = do ($) ->
  # we want to load our data from the local storage if possible
  userKey = "users"
  timestampKey = "mostRecentUpdate"
  loadingNewData = false

  # we use the stored time (= most recent update for this user) as a proxy
  # for whether data has been stored
  userDataAvailable = () ->
    !loadingNewData && store.get(timestampKey)

  storeUsers = (results) ->
    # store the users
    userdata.users = results.users
    store.set(userKey, results.users)
    store.set(timestampKey, results.mostRecentUpdate)
    # loading is done!
    loadingNewData = false

  error = (jQevent, errorData) ->
    alert("Error! %o", errorData)

  loadUserData = (remoteUpdateTime) ->
    mostRecentUpdateTime = store.get("mostRecentUpdateTime")
    if mostRecentUpdateTime && mostRecentUpdateTime >= remoteUpdateTime
      # load from local storage
      userdata.users = store.get(userKey);
    else
      # we have to load data from the server
      # first, prevent the system from using local data
      loadingNewData = true
      $.ajax({
        url: "/home/user_data",
        method: "get",
        success: storeUsers,
        error: error
      })


  userdata =
    users: []
    loadUserData: loadUserData
