describe("GoogleAuth", function() {  
  it("should exist", function() {
    expect(PK).toBeDefined();
    expect(PK.GoogleAuth).toBeDefined();
  })

  var auth;
  
  // track the nodes we sometimes use
  var trafficlightNode, errorNode, successNode;
  beforeEach(function() {
    loadFixtures('google_auth_fixture.html');

    // nodes we spy against
    errorNode = $("#generalError");
    successNode = $("#signIn");
    trafficlightNode = $("#signinFlow");
    
    // neuter reload/refresh
    auth = PK.GoogleAuth;
    // stub out reload/restart so the page doesn't get refresh
    spyOn(auth, "reloadOnComplete");
    spyOn(auth, "restart");
    
    // run all tests w/o huge wait
    auth.reactionTime = 0;
    $.fx.off = true;
  })

  describe("initialization", function() {
    describe("setting up trafficlight", function() {
      var steps, hash;

      beforeEach(function() {
        // neuter Ajax requests
        spyOn($, "ajax");

        // mock up the look of the google_auth page
        hash = {access_token: "foobar", expires: '3600'};
        hash_string = "access_token=foobar&expires=3600";
        document.location.hash = hash_string;

        auth.init();
        steps = trafficlightNode.trafficlight("option", "steps");
      })
      
      it("sets up trafficlight on the appropriate note", function() {
        // since we can't spy on $() directly, we have to look for indirect effects 
        expect(trafficlightNode.data("trafficlight")).toBeDefined();
      })

      // some of this could be merged into the next set of tests, which also contain this info
      it("sets up two steps", function() {
        expect(steps.length).toBe(2);
      })
    
      it("sets the first step's selector to #identifyUser", function() {
        expect(steps[0].selector).toBe("#identifyUser");
      })
      
      it("sets the first URL to a function returning google_login", function() {
        expect(steps[0].url(null, {args: {}})).toBe("google_login");          
      })
      
      it("sets the first step to be post", function() {
        expect(steps[0].method).toBe("post");          
      })
      
      it("sets the args for the first step based on the token in document.location.hash", function() {
        for (var key in hash) {
          expect(steps[0].args[key]).toBe(hash[key]);
        }
      })
      
      it("sets the second step's selector to #identifyUser", function() {
        expect(steps[1].selector).toBe("#getContacts");
      })
      
      it("sets the second URL to google_populate_contacts", function() {
        expect(steps[1].url).toBe("google_populate_contacts");          
      })
      
      it("sets the second step to be post", function() {
        expect(steps[1].method).toBe("post");          
      })
    })
  })

  describe("authentication", function() {
    // tell mockjax how to behave
    var ajaxBehavior, stepsCalled;
    
    beforeEach(function() {       
      // all the different values that could be returned
      stepsCalled = {};

      var defaultBehavior = {
        // response is returned if !(isError && isAjaxTimeout)
        // defined for individual steps
        response: {},
        
        // is our service timing out?  
        // distinct from Google timeout below
        isAjaxTimeout: false,
        // error responses
        // error is substituted for response
        isError: false,
        resetTimeout: false,
        error: {
          validation: false,
          invalidToken: false,
          redirect: null,
          timeout: false,
          noToken: false,
          otherError: false
        },

        // return a 500
        isRealError: false
      }
      
      ajaxBehavior = {
        google_login: $.extend({}, defaultBehavior, {
          // normal response for step 1
          step: 1,
          selector: "#identifyUser",
          response: {
            needsToken: false,
            name: "Alex K",
            isNewUser: false
          }
        }),
        
        google_populate_contacts: $.extend({}, defaultBehavior, {
          // normal response for step 2
          step: 2,
          selector: "#getContacts",
          response: {
            newWithAddress: 3, 
            newWithoutAddress: 4,
            updated: 5,
            unimportable: 6
          }
        })      
      }
      
      // now mock ajax
      $.mockjax(function(settings) {
        var configuration = ajaxBehavior[settings.url];
        stepsCalled[configuration.step] = (stepsCalled[configuration.step] || 0) + 1;
        
        // allow us to simulate a timeout followed by a valid response
        if (configuration.resetTimeout) {
          configuration.isError = false;
          configuration.error.timeout = false;
        }
        
        var response = {status: 200, responseTime: 0, responseText: {}}
        if (configuration.isError) {
          $.extend(response.responseText, {error: configuration.error});
        }
        else if (configuration.isAjaxTimeout) {
          response.isTimeout = true;
        }
        else if (configuration.isRealError) {
          response.status = 500;
        }
        else {
          $.extend(response.responseText, configuration.response);
        }
        
        // for simplicity, we set all requests to async 
        // so the Jasmine spies, etc. are still available
        settings.async = false;
        
        return response;
      })
    })

    it("works fine if the user is already logged in", function() {
      expect(function() { auth.init(); }).not.toThrow();        
    })
      
    it("updates the user's name", function() {
      auth.init();
      expect($("#name")).toHaveHtml(ajaxBehavior.google_login.response.name);
    })
    
    describe("if it returns needing term on the first step", function() {
      beforeEach(function() {
        ajaxBehavior.google_login.response.needsTerms = true;
      })
      
      it("pauses trafficlight", function() {
        auth.init();
        expect(trafficlightNode.trafficlight("isStopped")).toBe(true);
      })
      
      it("shows the #acceptTerms box", function() {
        auth.init();
        expect($("#acceptTerms")).toBeVisible();          
      })
      
      it("shows an alert if you try to proceed without agreeing to terms", function() {
        auth.init();
        $("#termsCheck").attr("checked", false);        
        spyOn(auth, "showTermsAlert");

        $("#termsSubmit").click();
        expect(auth.showTermsAlert).toHaveBeenCalled();
      })
      
      describe("when the user accepts terms", function() {
        it("removes the terms box", function() {
          auth.init();
          $("#termsCheck").attr("checked", true);
          $("#termsSubmit").click();
          expect($("#acceptTerms")).toBeHidden();
        })

        it("reruns the first call after click", function() {
          auth.init();
          $("#termsCheck").attr("checked", true);        
          $("#termsSubmit").click();
          
          // it should have been called twice
          expect(stepsCalled["1"]).toBe(2);
        })
        
        it("doesn't rerun the first call until without auth being clicked", function() {
          auth.init();
          $("#termsCheck").attr("checked", true); 
          
          // it should have been called twice
          expect(stepsCalled["1"]).toBe(1);
        })

        it("includes accepted_terms = true with the next request box and proceed", function() {
          auth.init();
          $("#termsCheck").attr("checked", true);        
          spyOn($, "ajax");
          $("#termsSubmit").click();
          // the next call will be the rerun
          var args = $.ajax.mostRecentCall.args[0].data;
          expect(args.accepted_terms).toBe(true);
        })  
      })
    })

    describe("errors", function() {
      var itShouldBehaveLikeError = function(stepName, error) {
        describe(issue + " occuring for " + stepName, function() {
          beforeEach(function() {
            ajaxBehavior[stepName].isError = true;
            ajaxBehavior[stepName].error[error] = true;
          })

          it("inserts the error node below the step node", function() {
            auth.init();
            expect($(ajaxBehavior[stepName].selector).next()).toBe("#generalError");
          })

          it("adds text to the error node", function() {
            auth.init();
            expect($("#generalError").html().length).toBeGreaterThan(0);
          })

          it("stops trafficlight", function() {
            auth.init();
            expect(trafficlightNode.trafficlight("isStopped")).toBe(true);          
          })
        })
      }
      
      var issue, issues = ["validation", "invalidToken", "timeout", "loginRequired", "noToken", "otherError"];
      var stepName, steps = ["google_login", "google_populate_contacts"];
      
      for (var i = 0; stepName = steps[i]; i++) {
        for (var j = 0; issue = issues[j]; j++) {
          itShouldBehaveLikeError(stepName, issue);        
        }
      }
      
      it("handles special error cases", function() { throw "not implemented" })
      it("handles needsTerms through error, not response", function() { throw "not implemented" })
    })

    it("tests completion", function() { throw "not implemented" })
  })
})