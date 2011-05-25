describe "PK.Login", () ->
  it "exists", () ->
    expect(PK.Login).toBeDefined()
  
  link = dialog = iframe = null  
  beforeEach () ->
    loadFixtures('login_fixture.html');
    link = $("#authLink") 
    dialog = $("#authIframeHolder")
    iframe = $("#authIframe")
  
  afterEach () ->
    $(".ui-dialog").remove()
    
  describe "init", () ->
    it "binds a click method onto the login link", () ->
      PK.Login.init()
      expect(link).toHandle("click")
    
  describe "when login is clicked", () ->
    it "opens a dialog box", () ->
      PK.Login.init()
      link.click()
      expect(dialog.dialog("isOpen")).toBe(true)
      
    it "renders the JST google_start template", () ->
      spyOn(PK, "render")
      PK.Login.init()
      link.click()
      # getting the value of the inserted content seems to be unreliable
      # so we'll proxy that (not well) by just making sure the content was rendered
      expect(PK.render).toHaveBeenCalled()
      expect(PK.render.mostRecentCall.args[0]).toBe("google_start")