var PK = PK || {};

PK.GoogleAuth = (function($, undefined) {
  // DOM elements we use
  var trafficlight, timeoutWarningNode, 
      timeoutErrorNode, errorNode, successNode;
      
  var termsError = "terms", errorCount;
  
  var checkForTerms = function(data) {
    if (data.response.needs_terms) {
      // pause the app
      // kick us back a step as well, so we rerun whatever caused it
      trafficlight("error", termsError);

      // show the terms
      $("#acceptTerms").slideDown();
      $("#termsSubmit").click(function() {
        if ($("#termsCheck").attr("checked")) {
          // mark that terms have been accepted
          data.step.args.acceptedTerms = true;
          // resume operation
          trafficlight("start");
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
    var stepElement = $(data.step.selector);
    
    if (errorData.text === "timeout") {
      if (!errorCount) {
        errorCount = 1;
        timeoutWarningNode.insertAfter(stepElement).slideDown();
        // give people a chance to read the error msg before starting again
        setTimeout(function() {
          timeoutWarningNode.slideUp();
          trafficlight("start");
        }, 3000)
      }
      else {
        timeoutErrorNode.insertAfter(stepElement).slideDown();
        // note that here, we don't resume the process
        // two timeouts means it's over
      }
    }
    else {
      errorNode.insertAfter(stepElement).html("We encountered an error (" + errorData.text + ")!  Please try again later.").slideDown();
    }
  }
    
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
        complete: function() {
          successNode.removeClass("trafficlight-todo").addClass("trafficlight-doing");
          setTimeout(function() {
            successNode.removeClass("trafficlight-doing").addClass("trafficlight-done");
          }, 1000);
        }
      })
      
      trafficlight = $("#signinFlow").trafficlight;
    }
  }
}(jQuery))