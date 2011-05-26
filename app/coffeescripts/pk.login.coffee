PK ?= {}

# define our login method
PK.Login = do ($) ->
  login = {}
  loginURL = loginWindow = null

  openLoginDialog = () ->
    loginWindow = window.open("about:blank", 'pk.login', 'width=516,height=390,toolbar=no,location=yes,directories=no,menubar=no')
    loginWindow.document.write PK.render("google_start", {loginURL: loginURL})
    
  init = (url) ->
    loginURL = url
    $("#authLink").click () -> openLoginDialog()
  
  login = 
    openLoginDialog: openLoginDialog
    init: init