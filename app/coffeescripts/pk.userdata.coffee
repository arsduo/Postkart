PK ||= {}

# define our local storage wrapper
PK.UserData = do () ->
  # we want to load our data from the local storage if possible
  userdata = {
    users = []
  }

  userKey = "users"
  loadingNewData = false
  
  # we use the stored time (= most recent update for this user) as a proxy
  # for whether data has been stored
  userDataAvailable = () ->
    !loadingNewData && store.get("mostRecentUpdateTime")
  
  loadUserData = (remoteUpdateTime) ->  
    mostRecentUpdateTime = store.get("mostRecentUpdateTime")
    if mostRecentUpdateTime && mostRecentUpdateTime >= remoteUpdateTime
      # load from local storage
      userdata.users = store.get(userKey);
    else
      # we have to load data from the server
      # first, prevent the system from using local data 
      loadingNewData = true
      $.get("/home/user_data")
      