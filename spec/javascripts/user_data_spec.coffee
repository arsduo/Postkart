describe "PK.UserData", () ->
  afterEach () ->
    $.mockjaxClear()
    
  it "exists", () -> expect(PK.UserData).toBeDefined()
 
  describe "flush", () ->
    it "clears the store", () ->
      spyOn(store, "clear")
      PK.UserData.flush()
      expect(store.clear).toHaveBeenCalled()
    
    it "delete user data", () ->
      PK.UserData.user = 2
      PK.UserData.flush()
      expect(PK.UserData.user).not.toBeDefined()
      
    it "delete user's contacts", () ->
      PK.UserData.contacts = 2
      PK.UserData.contactsByName = 3
      PK.UserData.flush()
      expect(PK.UserData.contacts).not.toBeDefined()
      expect(PK.UserData.contactsByName).not.toBeDefined()
  
    it "delete user data", () ->
      PK.UserData.user = 2
      PK.UserData.flush()
      expect(PK.UserData.user).not.toBeDefined()
      
    it "clears the storage time", () ->
      # we can test this by seeing if a time of 0 triggers an ajax request
      # meaning we have no stored data
      spyOn($, "ajax")
      PK.UserData.flush()
      PK.UserData.loadUserData(0)
      expect($.ajax).toHaveBeenCalled()
  
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
          expect(PK.UserData.isDataAvailable()).toBe(false)
      
        it "triggers the userLoadStartEvent event", () ->
          spyOnEvent($("body"), PK.UserData.userLoadStartEvent)
          PK.UserData.loadUserData(remoteUpdateTime);
          expect(PK.UserData.userLoadStartEvent).toHaveBeenTriggeredOn($("body"))
    
    itProcessesData = (options = {remoteUpdateTime: 123567, resultUser: {_id: "resultUser"}, resultContactsByName: [{_id: "abc"}], resultTime: 12345}) ->
      describe "processing data", () ->
        results = remoteUpdateTime = null

        beforeEach () ->
          results = 
            user: options.resultUser
            contactsByName: options.resultContactsByName
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
          
        it "stores the contactsByName as .contactsByName", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          expect(PK.UserData.contactsByName).toBe(results.contactsByName)

        it "saves the contactsByName to localStorage", () ->
          # this gets stored elsewhere
          PK.UserData.loadUserData(remoteUpdateTime)
          # technically, the key name is an internal implementation method
          # but Jasmine doesn't really support anything, and it's not that big a deal
          expect(store.set).toHaveBeenCalledWith("contactsByName", results.contactsByName)
          
        itBuildsContactsHash(options.resultContactsByName, remoteUpdateTime)

        it "does not save the user data to localStorage", () ->
          # this gets stored elsewhere
          PK.UserData.loadUserData(remoteUpdateTime)
          # technically, the key name is an internal implementation method
          # but Jasmine doesn't really support anything, and it's not that big a deal
          expect(store.set).not.toHaveBeenCalledWith("contacts", results.contacts)
      
        it "stores the timestamp to localStorage", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          expect(store.set).toHaveBeenCalledWith("mostRecentUpdate", results.mostRecentUpdate)
        
        it "sets user data flag to available", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          expect(PK.UserData.isDataAvailable()).toBe(true)

        it "triggers the userLoadSuccessEvent event", () ->
          spyOnEvent($("body"), PK.UserData.userLoadSuccessEvent)
          PK.UserData.loadUserData(remoteUpdateTime);
          expect(PK.UserData.userLoadSuccessEvent).toHaveBeenTriggeredOn($("body"))

        it "says the data is fresh", () ->
          PK.UserData.loadUserData(remoteUpdateTime);
          expect(PK.UserData.isDataStale()).toBe(false)
                
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
          previousAvailability = PK.UserData.isDataAvailable()
          PK.UserData.loadUserData(remoteUpdateTime);
          expect(PK.UserData.isDataAvailable()).toBe(previousAvailability)
        
        if includeStale # doesn't make sense for the "if no data locally available" tests
          describe "when stale data is around", () ->
            user = {_id: "stale data user:115"}
            contactsByName = [{_id: "stale data contacts:116"}]

            beforeEach () ->
              # set up store to return "stale" data tied to an old time
              store.get.andCallFake (key) ->
                switch key
                  when "mostRecentUpdate" then remoteUpdateTime - 1 
                  when "user" then user
                  when "contactsByName" then contactsByName
                              
            it "still loads stale data if available", () ->
              # run and error out on Ajax
              PK.UserData.loadUserData(remoteUpdateTime);
              # the stale data should still be loaded
              expect(PK.UserData.user).toBe(user)
              # lazy to not code separate logic to load a contacts object
              # but this shows it loads
              # and we do check the proper storage of contacts elsewhere
              expect(typeof PK.UserData.contacts).toBe("object")
              
            it "does fires the userLoadSuccessEvent", () ->
              spyOnEvent($("body"), PK.UserData.userLoadSuccessEvent)
              PK.UserData.loadUserData(remoteUpdateTime);
              expect(PK.UserData.userLoadSuccessEvent).toHaveBeenTriggeredOn($("body"))
            
            it "says the data is stale", () ->
              PK.UserData.loadUserData(remoteUpdateTime);
              expect(PK.UserData.isDataStale()).toBe(true)
    
    itBuildsContactsHash = (contactsByName, time) ->
     it "creates a contacts hash as .contacts", () ->
        PK.UserData.loadUserData(time)
        expect(typeof PK.UserData.contacts).toBe("object")

      it "indexes the contacts hash by ID based on contactsByName", () ->
        PK.UserData.loadUserData(time)
        contact = contactsByName[0]
        expect(PK.UserData.contacts[contact._id]).toBe(contact)      

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
        user = {_id: "defined in localStorage :145"}
        differentUser = {_id: "different user"}
        contactsByName = [{_id: "outdated contacts"}]
        
        beforeEach () ->
          # we need to define user locally since it has to be returned by store
          spyOn(store, "set")
          spyOn(store, "get").andCallFake (key) ->
            # technically this is an internal implementation detail, but unavoidable
            switch key
              when "mostRecentUpdate" then time
              when "user" then user
              when "contactsByName" then contactsByName
          
        # simulate newer data being available
        itFetchesData(time + 1)
        itProcessesData({
          remoteUpdateTime: time + 1 
          resultTime: time + 1
          startUser: user
          resultUser: differentUser
          resultContactsByName: contactsByName
        })
        itHandlesErrors(time + 1)
    
      describe "and we force an update with params[:reloadContacts]", () ->
        time = 12315
        user = {_id: "defined in localStorage :145"}
        differentUser = {_id: "different user"}
        contactsByName = [{_id: "outdated contacts"}]

        beforeEach () ->
          # we need to define user locally since it has to be returned by store
          spyOn(store, "set")
          spyOn(store, "get").andCallFake (key) ->
            # technically this is an internal implementation detail, but unavoidable
            switch key
              when "mostRecentUpdate" then time
              when "user" then user
              when "contactsByName" then contactsByName

        # simulate newer data being available
        itFetchesData(-1)
        itProcessesData({
          remoteUpdateTime: -1
          resultTime: time
          startUser: user
          resultUser: differentUser
          resultContactsByName: contactsByName
        })
        itHandlesErrors(-1)
    
      describe "and it's up to date", () -> 
        time = 123456
        user = {_id: "and is up to date"}
        contactsByName = [{_id: "up to date contacts"}]
        
        beforeEach () ->
          # we need to define user locally since it has to be returned by store
          spyOn(store, "set")
          spyOn(store, "get").andCallFake (key) ->
            # technically this is an internal implementation detail, but unavoidable
            switch key
              when "mostRecentUpdate" then time 
              when "user" then user
              when "contactsByName" then contactsByName
          
          $.mockjax () -> throw "Ajax request should not have been made!"
          
        it "returns the stored copy", () ->
          PK.UserData.loadUserData(time)
          expect(PK.UserData.user).toBe(user)
        
        itBuildsContactsHash(contactsByName, time)

        it "makes no Ajax requests", () ->
          spyOn($, "ajax");
          PK.UserData.loadUserData(time)
          expect($.ajax).not.toHaveBeenCalled()
          