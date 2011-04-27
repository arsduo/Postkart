var PK = PK || {};

PK.GoogleAuth = (function($, undefined) {
  // the return value
  var auth;
  
  // DOM elements we use
  var trafficlightNode, errorNode, successNode;
      
  var termsError = "terms", errorCount;
  
  var updateName = function(data) {
    var response = data.response;
    if (response.name) {
      $("#name").html(response.name);
    }
  }

  var error = function(jQevent, errorData) {
    var stepElement = $(errorData.step.selector);
    var showError = function(text) {
      errorNode.html(text).insertAfter(stepElement).slideDown();
    }
    var hideError = function() { errorNode.slideUp(); }
    var errorDetails = errorData.details;
	
	  // special case errors first
    if (errorData.text === "timeout" || errorDetails.timeout) {
      if (!errorCount) {
        errorCount = 1;
        showError("Google isn't responding!  Let's try again...");
        // give people a chance to read the error msg before starting again
        setTimeout(function() {
          hideError();
          trafficlightNode.trafficlight("start");
        }, auth.reactionTime)
      }
      else {
        showError("Google seems to be down :( please try again later.")
        // note that here, we don't resume the process
        // two timeouts means it's over
      }
    }
    else if (errorDetails.needsTerms) {
      // show the terms dialog
      $("#acceptTerms").slideDown();
      $("#termsSubmit").click(function() {
        if ($("#termsCheck").attr("checked")) {
          // mark that terms have been accepted
          errorData.step.args.accepted_terms = true;
          // resume operation
          trafficlightNode.trafficlight("start");
          $("#acceptTerms").slideUp();
        }
        else {
          auth.showTermsAlert();
        }
      })
    }
    else if (errorDetails.loginRequired || (errorDetails.invalidToken && errorDetails.retry)) {
      showError("Oops! You need to be logged in for this.  Starting over...");
      setTimeout(function() {
        auth.restart();
      }, auth.reactionTime);
    }
    // generic errors
    else {
      showError("We encountered an error!  Please try again later.");
      try { console.log("Uncaught error: %o", errorData) } catch (e) {}
    }
  }
  
  var checkResponse = function(jQevent, data) {
    var errorData = data.response.error;
    if (errorData) {
    	trafficlightNode.trafficlight("error", "serverError", errorData);
    }
    else {
      // reset the error count, since we had a successful call
      errorCount = 0;
    }
  }
    
  var auth = {
    // delay to let users react to what's happening
    reactionTime: 2000,
    
    init: function() {
      errorNode = $("#generalError");
      successNode = $("#signIn");
      trafficlightNode = $("#signinFlow");
      errorCount = 0;
      
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
            success: updateName,
            method: "post"
          },
          { selector: "#getContacts",  url: "google_populate_contacts", method: "post"}
        ],
      
        error: error,
        success: checkResponse,
        
        complete: function() {
          successNode.removeClass("trafficlight-todo").addClass("trafficlight-doing");
          setTimeout(function() {
            successNode.removeClass("trafficlight-doing").addClass("trafficlight-done");
            PK.GoogleAuth.reloadOnComplete();
          }, auth.reactionTime);  
        }
      })
    },
    
    // these are separated out mainly to allow us to test
    // since we can't stop browser functions
    reloadOnComplete: function() {
      window.parent.location.reload();
    },
    
    restart: function() {
      window.location = "google_start";
    },
    
    showTermsAlert: function() {
      alert("You must accept the terms to continue!");      
    }
  };
  
  return auth;
}(jQuery))