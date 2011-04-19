describe("GoogleAuth", function() {
  /* page fixture */
  var clean$ = window.jQuery;
  
  it("should exist", function() {
    expect(PK).toBeDefined();
    expect(PK.GoogleAuth).toBeDefined();
  })
  
  // track the nodes we sometimes use
  var trafficlightNode, errorNode, successNode;
  beforeEach(function() {
    loadFixtures('google_auth_fixture.html');

    // nodes we spy against
    errorNode = $("#generalError");
    successNode = $("#signIn");
    trafficlightNode = $("#signinFlow");
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

        PK.GoogleAuth.init();
        
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
        }
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
        
        google_populate_callback: $.extend({}, defaultBehavior, {
          // normal response for step 1
          response: {
            newWithAddress: 3, 
            newWithoutAddress: 4,
            updated: 5,
            unimportable: 6
          }
        })      
      }
    })
  })
})