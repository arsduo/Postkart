var PK = PK || {};

PK.GoogleAuth = (function($, undefined) {
  // the return value
  var auth;
  
  // DOM elements we use
  var trafficlightNode, errorNode, successNode;
      
  var termsError = "terms", errorCount;
  
  var checkForTerms = function(data) {
    var response = data.response;
    if (response.name) {
      console.log($("#name"))
      $("#name").html(response.name);
    }
    
    if (response.needsTerms) {
      // pause the app
      // kick us back a step as well, so we rerun whatever caused it
      trafficlightNode.trafficlight("error", termsError);
      // show the terms
      $("#acceptTerms").slideDown();
      $("#termsSubmit").click(function() {
        if ($("#termsCheck").attr("checked")) {
          // mark that terms have been accepted
          data.step.args.accepted_terms = true;
          // resume operation
          trafficlightNode.trafficlight("start");
          $("#acceptTerms").slideUp();
        }
        else {
          alert("You must accept the terms to continue!");
        }

        return false;
      })
    }
  }

  var error = function(jQevent, errorData) {
    var stepElement = $(errorData.step.selector);
    var showError = function(text) {
      errorNode.insertAfter(stepElement).html(text).slideDown();
    }
    var hideError = function() { errorNode.slideUp(); }
    
    if (errorData.text === "timeout") {
      if (!errorCount) {
        errorCount = 1;
        showError("Google isn't responding!  Let's try again...");
        // give people a chance to read the error msg before starting again
        setTimeout(function() {
          hideError();
          trafficlightNode.trafficlight("start");
        }, 3000)
      }
      else {
        showError("Google seems to be down :( please try again later.")
        // note that here, we don't resume the process
        // two timeouts means it's over
      }
    }
    else if (errorData.text === "loginRequired") {
      showError("Oops! You need to be logged in for this.  Starting over...");
      setTimeout(auth.restart, 2000);
    }
    else if (errorData.text !== "terms") {
      showError("We encountered an error!  Please try again later.");
      try { console.log("Error: %o", errorData) } catch (e) {}
    }
  }
  
  var checkResponse = function(jQevent, data) {
    var errorData = data.response.error;
    if (errorData) {
      if (errorData.loginRequired) {
        trafficlightNode.trafficlight("error", "loginRequired", errorData);
      }
      else {
        trafficlightNode.trafficlight("error", "other", errorData);
      }
    }
  }
    
  var auth = {
    init: function() {
      errorNode = $("#generalError");
      successNode = $("#signIn");
      trafficlightNode = $("#signinFlow");

      trafficlightNode.trafficlight({
        steps: [
          { selector: "#identifyUser", 
            url: function(lastResults, step) {
              // turn the args into a hash for compatibility with trafficlight
              var tokenInfo = document.location.hash.slice(1).split("&")
              var newArgs = {}, temp;
              for (var i = 0; i < tokenInfo.length; i++) { 
                temp = tokenInfo[i].split("="); 
                newArgs[temp[0]] = temp[1]; 
              }
              step.args = $.extend(step.args, newArgs);
              return "google_login";
            },
            success: checkForTerms,
            method: "post"
          },
          { selector: "#getContacts",  url: "google_populate_contacts", method: "post"}
        ],
      
        error: error,
        success: checkResponse,
        
        complete: function() {
          successNode.removeClass("trafficlight-todo").addClass("trafficlight-doing");
          PK.GoogleAuth.reloadOnComplete();
        }
      })
    },
    
    // these are separated out mainly to allow us to test
    // since we can't stop browser functions
    reloadOnComplete: function() {
      setTimeout(function() {
        successNode.removeClass("trafficlight-doing").addClass("trafficlight-done");
        window.parent.location.reload();
      }, 1000);
    },
    
    restart: function() {
      window.location = "google_start";
    }
  };
  
  return auth;
}(jQuery))