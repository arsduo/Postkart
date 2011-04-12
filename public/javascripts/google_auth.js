var PK = PK || {};

PK.GoogleAuth = (function($, undefined) {
  // DOM elements we use
  var timeoutWarningNode, timeoutErrorNode, errorNode, successNode;


  // on load, assign some DOM nodes
  $(document).ready(function() {
    timeoutErrorNode = $("#timeoutError");
    timeoutWarningNode = $("#timeoutWarning");
    errorNode = $("#generalError");
    successNode = $("#signIn");
  });
  
  return {
    init: function() {
      $("#signinFlow").trafficlight({
        steps: [
          {
            
          }
        
        ]
      })
    },
    saveToken: function() {
      var serverArgs = document.location.hash.slice(1);
      $.post("google_login", serverArgs, function(result) {
        if (result.name) {
          $("body").append("<div>Welcome " + (result.is_new_user ? "" : "back ") + "to Postkart, " + result.name + "!</div>");
          //if (result.is_new_user) {
            $("body").append("<div>Getting your contacts...</div>");
            $.post("google_populate_contacts", function(result) {
              console.log(result);
              //document.location.href = "/";
            })
          //}
        }
      });
    },
  }
  
}(jQuery))