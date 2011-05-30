describe "PK functions", () ->
  it "exists", () ->
    expect(PK).toBeDefined()
  
  describe "render", () ->
    oldJST = null
    
    beforeEach () ->
      oldJST = JST
      JST =
        google_start: () -> 
        trip_contact: () -> 
        mobile_trip_contact: () -> 
      
    afterEach () ->
      JST = oldJST
  
    describe "if not mobile", () ->
      it "renders the given JST", () ->
        spyOn(JST, "google_start")
        PK.render("google_start")
        expect(JST.google_start).toHaveBeenCalled();
      
    describe "if mobile", () ->
      beforeEach () ->
        PK.mobile = true
      
      afterEach () ->
        PK.mobile = false
      
      it "renders the mobile version of the JST if it exists", () ->
        spyOn(JST, "mobile_trip_contact")
        spyOn(JST, "trip_contact")
        PK.render("trip_contact")
        expect(JST.mobile_trip_contact).toHaveBeenCalled();

      it "does not render the regular version if a mobile one exists", () ->
        spyOn(JST, "trip_contact")
        PK.render("trip_contact")
        expect(JST.trip_contact).not.toHaveBeenCalled();
        
      it "renders the regular version of the JST if no mobile version exists", () ->
        spyOn(JST, "google_start")
        PK.render("google_start")
        expect(JST.google_start).toHaveBeenCalled();
    
      it "throws an exception if the template doesn't exist", () ->
        templateName = "foobar"
        expect(() -> PK.render(templateName)).toThrow()

      it "includes the template name in the exception if template doesn't exist", () ->
        templateName = "foobar"
        message = ""
        try 
          PK.render(templateName)
        catch e
          message = e
        expect(message).toMatch(new RegExp(templateName))
        
    it "wraps the arguments in an array if they're not", () ->
      args = {x: 2}
      spyOn(JST, "google_start")
      PK.render("google_start", args)
      expect(JST.google_start).toHaveBeenCalled()
      # since this is called using apply, we want to make sure the arguments actually make it over
      expect(JST.google_start.mostRecentCall.args[0]).toEqual(args)

    it "works with properly formatted arguments", () ->
      args = [{x: 2}]
      spyOn(JST, "google_start")
      PK.render("google_start", args)
      # since this is called using apply, we want to make sure the arguments actually make it over
      expect(JST.google_start.mostRecentCall.args[0]).toEqual(args[0])
      
describe "mobileReady", () ->
  it "binds a listener to window.document that sets PK.mobileReady = true on mobileInit", () -> 
    PK.mobileReady = false
    $(window.document).trigger("mobileinit")
    expect(PK.mobileReady).toBe(true)