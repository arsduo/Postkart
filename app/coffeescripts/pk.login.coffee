PK ?= {}

# define our login method
PK.Login = do ($) ->
  login = {}
  loginURL = loginWindow = null

  createWindow = () ->
    loginWindow = window.open("about:blank", 'pk.login', 'width=516,height=390,toolbar=no,location=yes,directories=no,menubar=no')
  
  openLoginDialog = () ->
    login.createWindow().document.write PK.render("google_start", {loginURL: loginURL})
    
  init = (url) ->
    loginURL = url
    $("#authLink").click(openLoginDialog)
  
  login = 
    # technically doesn't need to be public, but we need it to test
    createWindow: createWindow
    init: init