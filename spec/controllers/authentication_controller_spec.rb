require 'spec_helper'

describe AuthenticationController do
  render_views
  
  include ApplicationHelper
  
  describe "GET 'google_start'" do
    it "is successful" do
      get 'google_start'
      response.should be_success
    end
    
    it "includes the Google Auth URL" do
      get 'google_start'
      response.body.should include(google_auth_url)
    end
  end
  
  describe "GET 'google_callback'" do
    it "is successful" do
      get 'google_callback'
      response.should be_success
    end
  end
  
  describe "POST 'google_login'" do
    it "returns :noToken => true if no token provided" do
      get 'google_login'
      JSON.parse(response.body)["error"]["noToken"].should be_true
    end
    
    context "with a token" do
      before :each do
        @args = {:access_token => "foo", :expires_in => 3600}
      end
      
      it "finds_or_creates a user from the token" do
        User.expects(:find_or_create_from_google_token).with(@args[:access_token]).returns(User.make)
        get 'google_login', @args
      end
      
      it "clears the :retried_invalid_token flag" do
        User.expects(:find_or_create_from_google_token).with(@args[:access_token]).returns(User.make)
        session[:retried_invalid_token] = true
        get 'google_login', @args
        session[:retried_invalid_token].should_not be_true
      end
      
      it "returns a hash of validation errors if the user isn't valid" do
        u = User.make
        u.stubs(:valid?).returns(false)
        errors = {"remote_accounts" => ["is invalid"]}
        u.stubs(:errors).returns(errors)
        User.expects(:find_or_create_from_google_token).with(@args[:access_token]).returns(u)

        get 'google_login', @args
        JSON.parse(response.body)["error"]["validation"].should == errors        
      end

      context "if the user is valid" do
        it "returns a hash with the user name" do
          name = "foo"
          User.stubs(:find_or_create_from_google_token).returns(User.make(:name => name))
          get 'google_login', @args
          JSON.parse(response.body)["name"].should == name
        end

        describe "using created_at as a proxy for new user status" do
          it "returns a hash with isNewUser = false if the user is not new" do
            User.stubs(:find_or_create_from_google_token).returns(User.make(:created_at => Time.now - 600))
            get 'google_login', @args
            JSON.parse(response.body)["isNewUser"].should be_false
          end          

          it "returns a hash with isNewUser = true if the user is new" do
            User.stubs(:find_or_create_from_google_token).returns(User.make(:created_at => Time.now - 1))
            get 'google_login', @args
            JSON.parse(response.body)["isNewUser"].should be_true
          end
        end

        shared_examples_for "signing the user in" do
          it "executes sign-in" do
            @u ||= User.make
            User.stubs(:find_or_create_from_google_token).returns(@u)
            controller.expects(:sign_in).with(:user, @u)
            get 'google_login', @args
          end
        end     

        context "for users who've previously accepted the terms" do
          it_behaves_like "signing the user in" # defined below
        end

        context "for users who just accepted the terms" do
          before :each do
            @args.merge!(:accepted_terms => true)
            @u = User.make(:accepted_terms => false, :created_at => Time.now - 600)
            User.stubs(:find_or_create_from_google_token).returns(@u)
          end

          it_behaves_like "signing the user in"

          it "updates and persists the accepted_terms flag" do
            get 'google_login', @args
            @u.accepted_terms.should be_true
            @u.changed?.should be_false
          end
        end
        
        context "for users who haven't accepted the terms" do
          it "does not sign that user in" do
            u = User.make(:accepted_terms => false)
            User.stubs(:find_or_create_from_google_token).returns(u)
            controller.expects(:sign_in).never
            get 'google_login', @args
          end

          it "returns a hash with needsTerms = true" do
            User.stubs(:find_or_create_from_google_token).returns(User.make(:accepted_terms => false))
            get 'google_login', @args
            JSON.parse(response.body)["needsTerms"].should be_true
          end
        end  
      end

      context "when Google says the token is invalid" do
        before :each do
          User.stubs(:find_or_create_from_google_token).raises APIManager::Google::InvalidTokenError          
        end
        
        it "returns :invalid_token => true" do
          get 'google_login', @args
          JSON.parse(response.body)["error"]["invalidToken"].should be_true
        end
        
        context "the first time" do
          it "sets the session[:retried_invalid_token] to avoid an infinite loop" do
            get 'google_login', @args
            session[:retried_invalid_token].should be_true
          end

          it "returns a redirect to google_start" do
            get 'google_login', @args
            JSON.parse(response.body)["error"]["redirect"].should match("google_start")
          end
        end
        
        it "does not return a redirect on subsequent errors" do
          session[:retried_invalid_token] = true
          get 'google_login', @args
          JSON.parse(response.body)["error"]["redirect"].should be_nil
        end
      end
    end
  end

  describe "POST 'google_populate_contacts'" do
    it "needs tests"
  end
end
