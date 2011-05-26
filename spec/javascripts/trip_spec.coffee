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
    
 