PK ?= {}

# define our login method
PK.Login = do ($) ->
  login = {}
  loginURL = null

  openLoginDialog = (loginURL) ->
    # open up a dialog box for the authentication flow
    $("#authIframeHolder").dialog({
      dialogClass: "authDialog",
      width: 516,
      height: 390
      minHeight: 390
    })
    setupIframe()
  
  setupIframe = () ->
    # write the start splash-page into the iframe, which gets it going 
    $("#authIframe")
      .attr("src", "about:blank;")[0]
      .contentDocument.write PK.render("google_start", {loginURL: loginURL})
    
    
  init = (url) ->
    loginURL = url
    $("#authLink").click () -> openLoginDialog()
  
  login = 
    openLoginDialog: openLoginDialog
    setupIframe: setupIframe
    init: init