describe "PK.Login", () ->
  it "exists", () ->
    expect(PK.Login).toBeDefined()
  
  fakeWindow = 
    document: 
      write: () ->
  
  link = window = null 
  
  beforeEach () ->
    loadFixtures('login_fixture.html');
    link = $("#authLink") 

  describe "init", () ->
    it "binds a click method onto the login link", () ->
      PK.Login.init()
      expect(link).toHandle("click")
    
  describe "when login is clicked", () ->
    beforeEach () ->
      spyOn(PK.Login, "createWindow").andReturn(fakeWindow)
      
    it "opens a window", () ->
      PK.Login.init()
      link.click()
      expect(PK.Login.createWindow).toHaveBeenCalled()
      
    it "renders the google_start template", () ->
      spyOn(PK, "render")
      PK.Login.init()
      link.click()
      expect(PK.render).toHaveBeenCalled()
      expect(PK.render.mostRecentCall.args[0]).toBe("google_start")

    it "writes the content of the google_start template to the new window", () ->
      text = "some my text"
      spyOn(PK, "render").andReturn(text)
      spyOn(fakeWindow.document, "write")
      PK.Login.init()
      link.click()
      expect(fakeWindow.document.write).toHaveBeenCalledWith(text)
      
    it "renders the JST google_start template", () ->
      spyOn(PK, "render")
      PK.Login.init()
      link.click()
      # getting the value of the inserted content seems to be unreliable
      # so we'll proxy that (not well) by just making sure the content was rendered
      expect(PK.render).toHaveBeenCalled()
      expect(PK.render.mostRecentCall.args[0]).toBe("google_start")
      
    it "returns false, preventing other actions", () ->
      spyOn(PK, "render")
      PK.Login.init()
      triggered = false
      # this shouldn't fire because a previous handler returns false
      link.click () -> triggered = true 
      expect(triggered).toBe(false)
