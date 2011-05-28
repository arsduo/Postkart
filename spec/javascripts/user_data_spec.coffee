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

    it "delete user's trips", () ->
      PK.UserData.trips = 2
      PK.UserData.tripsByDate = 3
      PK.UserData.flush()
      expect(PK.UserData.trips).not.toBeDefined()
      expect(PK.UserData.tripsByDate).not.toBeDefined()  

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
  
  describe "cardSent", () ->
    it "adds the recipient to the trip's list", () ->
      trip = {_id: "abc", recipients: []}
      contact = {_id: "def"}
      PK.UserData.tripsByDate = [trip]
      PK.UserData.cardSent(trip, contact)
      PK.UserData.tripsByDate[0].recipients[0].should == contact._id
  
  describe "whenAvailable", () ->
    beforeEach () ->
      PK.UserData.flush()
      
    it "fires the fn immediately if user data is available", () ->
      # simulate user data
      PK.UserData.user = {}
      fired = false
      PK.UserData.whenAvailable () ->
        fired = true
      expect(fired).toBe(true)

    it "does not fire the fn immediately if user data is not available", () ->
      # simulate user data
      fired = false
      PK.UserData.whenAvailable () ->
        fired = true
      expect(fired).toBe(false)

    it "fires the fn on user data load if not available", () ->
      # simulate user data
      fired = false
      PK.UserData.whenAvailable () ->
        fired = true
      $("body").trigger(PK.UserData.userLoadSuccessEvent)
      expect(fired).toBe(true)

  describe "loadUserData", () ->
    # common functions
    # remoteUpdateTime is the timestamp given on page load to see if data is stale
    
    beforeEach () ->
      PK.UserData.flush()
    
    itFetchesData = (remoteUpdateTime = 123, mostRecentUpdate = null) ->
      describe "fetching data", () ->
        updateTime = null
        
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
        
        it "includes the previous update", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          args = $.ajax.mostRecentCall.args[0]
          expect(args.params.since).toBe(mostRecentUpdate)
        
        it "sets user data flag to unavailable", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          expect(PK.UserData.isDataAvailable()).toBe(false)
      
        it "triggers the userLoadStartEvent event", () ->
          spyOnEvent($("body"), PK.UserData.userLoadStartEvent)
          PK.UserData.loadUserData(remoteUpdateTime);
          expect(PK.UserData.userLoadStartEvent).toHaveBeenTriggeredOn($("body"))
    
    itProcessesData = (options = {remoteUpdateTime: 123567, resultUser: {_id: "resultUser"}, resultTrips: [{_id: "foo", created_at: 123}], resultContactsByName: [{_id: "abc", last_name: "Zed"}], resultTime: 12345}) ->
      describe "processing data", () ->
        resultsHolder = {}
        results = remoteUpdateTime = null

        beforeEach () ->
          results = resultsHolder.results = 
            user: options.resultUser
            contactsByName: options.resultContactsByName
            trips: options.resultTrips
            mostRecentUpdate: options.resultTime
            
          remoteUpdateTime = options.remoteUpdateTime
          
          PK.UserData.user = options.startUser
          $.mockjax({
            url: "/home/user_data",
            responseText: results
          })
                  
        itMergesUpdates("contacts", "contactsByName", resultsHolder, "last_name", options.remoteUpdateTime)

        itMergesUpdates("trips", "tripsByDate", resultsHolder, "created_at", options.remoteUpdateTime)

        it "stores the user results as .user", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          expect(PK.UserData.user).toBe(results.user)
          
        it "saves the user data to localStorage", () ->
          PK.UserData.loadUserData(remoteUpdateTime)
          # technically, the key name is an internal implementation method
          # but Jasmine doesn't really support anything, and it's not that big a deal
          expect(store.set).toHaveBeenCalledWith("user", results.user)

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
          PK.UserData.loadUserData(remoteUpdateTime);
          # data will be available based on whether there's data, regardless of loading status
          expect(PK.UserData.isDataAvailable()).toBe(!!(store.get("user") || PK.UserData.user))
        
        if includeStale # doesn't make sense for the "if no data locally available" tests
          describe "when stale data is around", () ->
            user = {_id: "stale data user:115"}
            contactsByName = [{_id: "stale data contacts:116", last_name: "Ryan"}]

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

    itMergesUpdates = (name, source, resultsHolder, sortKey, time) ->
      # these also implicitly tests that the updated items are made
      # available as PK.UserData[source]
      describe "merging #{name}", () ->      
        getIds = (list) -> item._id for item in list
        
        results = null
        beforeEach () ->
          results = resultsHolder.results
    
        it "mixes the old and new user data together", () ->
          allIDs = getIds([].concat(PK.UserData[source] || []).concat(results[source] || []))
          PK.UserData.loadUserData(time)
          newIDs = getIds(PK.UserData[source])
          expect(newIDs.indexOf(id)).not.toBe(-1) for id in allIDs
            
        it "updates existing records", () ->
          items = PK.UserData[source]
          if items && items.length > 0
            firstItem = items[0]
            # fake up a varied version of item last name
            newData = {}; 
            newData[sortKey] = firstItem[sortKey] + "1"
            results[source] = [$.extend({}, firstItem, newData)]

            # it should update that one record
            PK.UserData.loadUserData(time)
            expect(PK.UserData[source][0][sortKey] + "").toBe(results[source][0][sortKey] + "")

        it "sorts items appropriately", () ->
          PK.UserData.loadUserData(time)
          # it should update that one record
          names = (item[sortKey] for item in PK.UserData[source])
          shouldBe = (item[sortKey] for item in PK.UserData[source].
                        sort((c1, c2) -> if c1[sortKey] < c2[sortKey] then -1 else 1))
          # should be sorted the same way
          expect(names.indexOf(name)).toBe(shouldBe.indexOf(name)) for name in names

        itBuildsHash(name, source, time)
        
        it "saves the #{source} to localStorage", () ->
          # this gets stored elsewhere
          PK.UserData.loadUserData(time)
          # technically, the key name is an internal implementation method
          # but Jasmine doesn't really support anything, and it's not that big a deal
          expect(store.set).toHaveBeenCalledWith(source, PK.UserData[source])

        it "does not save the #{name} dictionary to localStorage", () ->
          # this gets stored elsewhere
          PK.UserData.loadUserData(time)
          # technically, the key name is an internal implementation method
          # but Jasmine doesn't really support anything, and it's not that big a deal
          expect(store.set).not.toHaveBeenCalledWith(name, PK.UserData[name])
    
    itBuildsHash = (name, source, time) ->
      it "creates a hash as .#{name}", () ->
        PK.UserData.loadUserData(time)
        expect(typeof PK.UserData[name]).toBe("object")

      it "indexes the #{name} hash by ID based on #{source}", () ->
        PK.UserData.loadUserData(time)
        for item in PK.UserData[source]
          expect(PK.UserData[name][item._id]).toBe(item)
     
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
        contactsByName = [{_id: "outdated contacts", last_name: "Love"}]
        resultContacts = [{_id: "less outdated contacts", last_name: "Caring"}, {_id: "outdated contacts", last_name: "Happiness"}]
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
        itFetchesData(time + 1, time)
        itProcessesData({
          remoteUpdateTime: time + 1 
          resultTime: time + 1
          startUser: user
          resultUser: differentUser
          resultContactsByName: resultContacts
        })
        itHandlesErrors(time + 1)
    
      describe "and we force an update with params[:reloadContacts]", () ->
        time = 12315
        user = {_id: "defined in localStorage :145"}
        differentUser = {_id: "different user"}
        contactsByName = [{_id: "outdated contacts", last_name: "Bar"}]

        beforeEach () ->
          # we need to define user locally since it has to be returned by store
          spyOn(store, "set")
          spyOn(store, "get").andCallFake (key) ->
            # technically this is an internal implementation detail, but unavoidable
            switch key
              when "mostRecentUpdate" then time
              when "user" then user
              when "contactsByName" then contactsByName
        
        it "flushes existing data", () ->
          spyOn(PK.UserData, "flush")
          PK.UserData.loadUserData(-1)
          expect(PK.UserData.flush).toHaveBeenCalled()

        # simulate newer data being available
        itFetchesData(-1, time)
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
        contactsByName = [{_id: "up to date contacts", last_name: "Nina"}]
        
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
        
        itBuildsHash("contacts", "contactsByName", time)

        it "makes no Ajax requests", () ->
          spyOn($, "ajax");
          PK.UserData.loadUserData(time)
          expect($.ajax).not.toHaveBeenCalled()
          