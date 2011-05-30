describe "PK.Trip", () ->
  it "exists", () ->
    expect(PK.Trip).toBeDefined()

  trips = tripsByDate = trip = contacts = contactsByName = null
  
  beforeEach () ->
    # simulate a user
    PK.UserData.user = {}
    # mock trip
    trip = {_id: "abc", description: "My Awesome trip!", recipients: ["345"]}
    PK.UserData.trips = trips = {}
    trips[trip._id] = trip

    # mock up a bunch of user data
    PK.UserData.contactsByName = contactsByName = [{_id: "123", last_name: "bar"}, {_id: "345", last_name: "foo"}]
    PK.UserData.contacts = contacts = {"123": contactsByName[0], "345": contactsByName[1]}
    PK.UserData.tripsByDate = tripsByDate = [trip]
    
    loadFixtures('trip_fixture.html');
        
  describe "init", () ->
    it "queues initialization for user data", () ->
      spyOn(PK.UserData, "whenAvailable")
      PK.Trip.init()
      expect(PK.UserData.whenAvailable).toHaveBeenCalled()
      
    it "update the tripName field with the description of the trip", () ->
      PK.Trip.init(trip)
      expect($("#tripName")).toHaveHtml(trip.description)
    
    describe "rendering lists", () ->
      it "turns all send buttons into buttons", () ->
      it "binds all send buttons to send the card", () ->

      describe "if mobile", () ->
        it "binds all show buttons to show the dialog"

      describe "rendering unsent contacts", () ->
        it "renders unsent contacts in name order", () ->
        it "appends the contents to the tripContacts list", () ->
        describe "if mobile", () ->
          it "enhances the list", () ->
