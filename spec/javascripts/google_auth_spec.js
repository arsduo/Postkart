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

        // keep $.mobile from freaking out
        $.mobile.hashListeningEnabled = false;

        // mock up the look of the google_auth page
        hash = {access_token: "foobar", expires: '3600'};
        hash_string = "access_token=foobar&expires=3600";
        document.location.hash = hash_string;

        auth.init();
        steps = trafficlightNode.trafficlight("option", "steps");
      })
      
      afterEach(function() {
        $.mobile.hashListeningEnabled = true;
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
 
     describe("if it returns needing terms", function() {
      beforeEach(function() {
        ajaxBehavior.google_login.isError = true;
        ajaxBehavior.google_login.error.needsTerms = true;
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

          it(error + " on " + stepName + " inserts the error node below the step node", function() {
            auth.init();
            expect($(ajaxBehavior[stepName].selector).next("li")).toBe("#generalError");
          })

          it(error + " on " + stepName + " adds text to the error node", function() {
            auth.init();
            expect($("#generalError").html().length).toBeGreaterThan(0);
          })

          it(error + " on " + stepName + " stops trafficlight", function() {
            auth.init();
            expect(trafficlightNode.trafficlight("isStopped")).toBe(true);          
          })
        })
      }
      
      var issue, issues = ["validation", "invalidToken", "timeout", "loginRequired", "noToken", "otherError"];
      var stepName, steps = ["google_login", "google_populate_contacts"];
      
      for (var i = 0; i < steps.length; i++) {
        stepName = steps[i];
        
        // test common error functions
        for (var j = 0; j < issues.length; j++) {
          issue = issues[j];
          itShouldBehaveLikeError.apply(this, [stepName, issue]);        
        }

        // test special cases for each step
        it("for " + stepName + " restarts the app for loginRequired (after a delay)", function() {       
          ajaxBehavior[stepName].isError = true;
          ajaxBehavior[stepName].error.loginRequired = true;
          auth.init();
          waits(auth.reactionTime + 1);
          runs(function() {
            expect(auth.restart).toHaveBeenCalled();            
          })
        })

        it("for " + stepName + " restarts login for invalidToken with retry = true", function() { 
          ajaxBehavior[stepName].isError = true;
          ajaxBehavior[stepName].error.invalidToken = true;
          ajaxBehavior[stepName].error.retry = true;
          auth.init();
          waits(auth.reactionTime + 1);
          runs(function() {
            expect(auth.restart).toHaveBeenCalled();            
          })
        })

        it("for " + stepName + " does not restart login for invalidToken with retry = false", function() { 
          ajaxBehavior[stepName].isError = true;
          ajaxBehavior[stepName].error.invalidToken = true;
          ajaxBehavior[stepName].error.retry = false;
          auth.init();
          waits(auth.reactionTime + 1);
          runs(function() {
            expect(auth.restart).not.toHaveBeenCalled();            
          })
        })

        it("for " + stepName + " automatically retries once (and only once) if the requests time out", function() { 
          ajaxBehavior[stepName].isError = true;
          ajaxBehavior[stepName].error.timeout = true;
          auth.init();
          // it should have been called twice, after a delay
          waits(auth.reactionTime + 1);
          runs(function() {
            expect(stepsCalled[i]).toBe(2);              
          })
        })
          
        it("for " + stepName + " continues normally if the call after the timeout succeeeds", function() {
          ajaxBehavior[stepName].isError = true;
          ajaxBehavior[stepName].resetTimeout = true;
          ajaxBehavior[stepName].error.timeout = true;
          
          auth.init();
          waits(auth.reactionTime + 1);
          runs(function() {
            expect(trafficlightNode.trafficlight("isFinished")).toBe(true);          
          })
        })
      }
      
      it("doesn't fail if each step times out only once", function() {
        ajaxBehavior.google_login.isError = true;
        ajaxBehavior.google_login.resetTimeout = true;
        ajaxBehavior.google_login.error.timeout = true;
        ajaxBehavior.google_populate_contacts.isError = true;
        ajaxBehavior.google_populate_contacts.resetTimeout = true;
        ajaxBehavior.google_populate_contacts.error.timeout = true;
        
        auth.init();
        waits(auth.reactionTime + 1);
        runs(function() {
          expect(trafficlightNode.trafficlight("isFinished")).toBe(true);          
        })
      })
    })

    describe("completion", function() { 
      it("sets the successNode's class to trafficlight-doing", function() {
        auth.init();
        expect(successNode).toHaveClass("trafficlight-doing");
      })
      
      it("sets the successNode's class to trafficlight-done after a short delay", function() {
        auth.init();
        waits(auth.reactionTime + 1);
        runs(function() {
          expect(successNode).toHaveClass("trafficlight-done");          
        })
      })

      describe("on desktops", function() {
        it("does not call reloadOnComplete immediately", function() {
          auth.init();
          expect(auth.reloadOnComplete).not.toHaveBeenCalled()
        })

        it("calls reloadOnComplete after a short delay", function() {
          auth.init();
          waits(auth.reactionTime + 1);
          runs(function() {
            expect(auth.reloadOnComplete).toHaveBeenCalled()
          })
        })        
      })
      
      describe("on mobile", function() {
        beforeEach(function() {
          PK.mobile = true;
          spyOn($.mobile, "changePage");
        })
        
        afterEach(function() {
          PK.mobile = false;
          // keep this off
          $.mobile.hashListeningEnabled = false;
        })
        
        it("enables hashListeningEnabled", function() {
          auth.init();
          waits(auth.reactionTime + 1);
          runs(function() {
            expect($.mobile.hashListeningEnabled).toBe(true);            
          })
        })

        it("loads the root page through jQuery mobile", function() {
          auth.init();
          waits(auth.reactionTime + 1);
          runs(function() {
            expect($.mobile.changePage).toHaveBeenCalledWith("/");
          })
        })
      })
    })
  })
})