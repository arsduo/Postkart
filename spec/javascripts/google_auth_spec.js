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
    var ajaxBehavior;
    
    beforeEach(function() {       
      // all the different values that could be returned
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
        error: {
          validation: false,
          needsTerms: false,
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
          response: {
            needsToken: false,
            name: "Alex K",
            isNewUser: false
          }
        }),
        
        google_populate_contacts: $.extend({}, defaultBehavior, {
          // normal response for step 1
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
        var response = {status: 200, responseTime: 0, responseText: {}}
        if (configuration.isError) {
          $.extend(response, {error: configuration.error});
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
  })
})