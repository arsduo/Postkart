describe "PK.UserData", () ->
  afterEach () ->
    $.mockjaxClear()
    
  it "exists", () -> expect(PK.UserData).toBeDefined()
 
  describe "flush", () ->
    it "needs tests", () ->
      expect(true).toBe(false)
  
  
  describe "loadUserData", () ->
    # common functions
    # remoteUpdateTime is the timestamp given on page load to see if data is stale
    
    beforeEach () ->
      PK.UserData.flush()
    
    itFetchesData = (remoteUpdateTime = 123) ->
      describe "fetching data", () ->
        beforeEach () ->
          spyOn($, "ajax")
        
        it "makes an Ajax request to /home/user_data", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          expect($.ajax).toHaveBeenCalled()
          args = $.ajax.mostRecentCall.args[0]
          expect(args.url).toBe("/home/user_data")
      
        it "makes a GET request", () -> 
          PK.UserData.loadUserData(remoteUpdateTime)
          args = $.ajax.mostRecentCall.args[0]
          expect(args.method).toBe("get")
        
        it "sets user data flag to unavailable", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          expect(PK.UserData.isUserDataAvailable()).toBe(false)
      
        it "triggers the userLoadStartEvent event", () ->
          spyOnEvent($("body"), PK.UserData.userLoadStartEvent)
          PK.UserData.loadUserData(remoteUpdateTime);
          expect(PK.UserData.userLoadStartEvent).toHaveBeenTriggeredOn($("body"))
    
    itProcessesData = (options = {remoteUpdateTime: 123567, resultUser: {id: "resultUser"}, resultContacts: {}, resultTime: 12345}) ->
      describe "processing data", () ->
        results = remoteUpdateTime = null

        beforeEach () ->
          results = 
            user: options.resultUser
            contacts: options.resultContacts
            mostRecentUpdate: options.resultTime
          
          remoteUpdateTime = options.remoteUpdateTime
          
          PK.UserData.user = options.startUser
          $.mockjax({
            url: "/home/user_data",
            responseText: results
          })
        
        it "stores the user results as .user", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          expect(PK.UserData.user).toBe(results.user)
      
        it "saves the user data to localStorage", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          # technically, the key name is an internal implementation method
          # but Jasmine doesn't really support anything, and it's not that big a deal
          expect(store.set).toHaveBeenCalledWith("user", results.user)

        it "stores the contacts as .contacts", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          expect(PK.UserData.contacts).toBe(results.contacts)

        it "saves the user data to localStorage", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          # technically, the key name is an internal implementation method
          # but Jasmine doesn't really support anything, and it's not that big a deal
          expect(store.set).toHaveBeenCalledWith("contacts", results.contacts)
      
        it "stores the timestamp to localStorage", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          expect(store.set).toHaveBeenCalledWith("mostRecentUpdate", results.mostRecentUpdate)
        
        it "sets user data flag to available", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          expect(PK.UserData.isUserDataAvailable()).toBe(true)

        it "triggers the userLoadSuccessEvent event", () ->
          spyOnEvent($("body"), PK.UserData.userLoadSuccessEvent)
          PK.UserData.loadUserData(remoteUpdateTime);
          expect(PK.UserData.userLoadSuccessEvent).toHaveBeenTriggeredOn($("body"))
  
    itHandlesErrors = (remoteUpdateTime = 123, includeStale = true) ->
      describe "when an error occurs", () ->   
        error = null
      
        beforeEach () ->
          $.mockjax({
            url: "/home/user_data"
            status: 500
          })
        
        it "triggers the userLoadFailedEvent event", () ->
          spyOnEvent($("body"), PK.UserData.userLoadFailedEvent)
          PK.UserData.loadUserData(remoteUpdateTime);
          expect(PK.UserData.userLoadFailedEvent).toHaveBeenTriggeredOn($("body"))
          
        it "provides the event with the errorData from jQuery", () ->
          eventData = null
          $("body").bind(PK.UserData.userLoadFailedEvent, (jQevent, errorData) ->
            # generic jQuery error code for 500s
            expect(errorData).toBe("error") 
          )          
          PK.UserData.loadUserData(remoteUpdateTime);
      
        it "clears the loading flag", () ->
          previousAvailability = PK.UserData.isUserDataAvailable()
          PK.UserData.loadUserData(remoteUpdateTime);
          expect(PK.UserData.isUserDataAvailable()).toBe(previousAvailability)
        
        if includeStale # doesn't make sense for the "if no data locally available" tests
          describe "when stale data is around", () ->
            user = {id: "stale data user:115"}
            beforeEach () ->
              # set up store to return "stale" data tied to an old time
              store.get.andCallFake (key) ->
                if key == "mostRecentUpdate" then remoteUpdateTime - 1 else user
              
            it "still loads stale data if available", () ->
              # run and error out on Ajax
              PK.UserData.loadUserData(remoteUpdateTime);
              # the stale data should still be loaded
              expect(PK.UserData.user).toBe(user)
              # lazy to not code separate logic to load a contacts object
              # but this shows it loads
              # and we do check the proper storage of contacts elsewhere
              expect(PK.UserData.contacts).toBe(user)
              
            it "does not fire the userLoadSuccessEvent", () ->
              spyOnEvent($("body"), PK.UserData.userLoadSuccessEvent)
              PK.UserData.loadUserData(remoteUpdateTime);
              expect(PK.UserData.userLoadSuccessEvent).not.toHaveBeenTriggeredOn($("body"))
            

    describe "if no data is available locally", () ->
      beforeEach () ->
        spyOn(store, "get")
        spyOn(store, "set")
                
      itFetchesData()
      itProcessesData()
      itHandlesErrors(1234, false)
    
    describe "if data is available in localStorage", () ->
      describe "and it's outdated", () ->
        time = 123456
        user = {id: "defined in localStorage :145"}
        differentUser = {id: "different user"}
        
        beforeEach () ->
          # we need to define user locally since it has to be returned by store
          spyOn(store, "set")
          spyOn(store, "get").andCallFake (key) ->
            # technically this is an internal implementation detail, but unavoidable
            if key == "mostRecentUpdate" then time else user
          
        # simulate newer data being available
        itFetchesData(time + 1)
        itProcessesData({
          remoteUpdateTime: time + 1 
          resultTime: time + 1
          startUser: user
          resultUser: differentUser
        })
        itHandlesErrors(time + 1)
    
      describe "and it's up to date", () -> 
        time = 123456
        user = {id: "and is up to date"}
        
        beforeEach () ->
          # we need to define user locally since it has to be returned by store
          spyOn(store, "set")
          spyOn(store, "get").andCallFake (key) ->
            # technically this is an internal implementation detail, but unavoidable
            if key == "mostRecentUpdate" then time else user
          
          $.mockjax () -> throw "Ajax request should not have been made!"
          
        it "returns the stored copy", () ->
          PK.UserData.loadUserData(time)
          expect(PK.UserData.user).toBe(user)

        it "makes no Ajax requests", () ->
          spyOn($, "ajax");
          PK.UserData.loadUserData(time)
          expect($.ajax).not.toHaveBeenCalled()
          