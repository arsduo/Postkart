require 'spec_helper'

describe AuthenticationController do
  render_views
  
  include ApplicationHelper
  
  describe "GET 'google_callback'" do
    it "is successful" do
      get 'google_callback'
      response.should be_success
    end
    
    it "turns off mobile hash listening if in mobile mode" do
      controller.stubs(:mobile_mode?).returns(true)
      get "google_callback"
      response.body.should include("$.mobile.hashListeningEnabled = false")
    end
    
    it "does not turn off mobile hash listening if not in mobile mode" do
      controller.stubs(:mobile_mode?).returns(false)
      get "google_callback"
      response.body.should_not include("$.mobile.hashListeningEnabled = false")
    end
  end
  
  describe "POST 'google_login'" do
    it "returns :noToken => true if no token provided" do
      get 'google_login'
      MultiJson.decode(response.body)["error"]["noToken"].should be_true
    end
    
    context "with a token" do
      before :each do
        @url = "google_login"
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
        MultiJson.decode(response.body)["error"]["validation"].should == errors        
      end

      context "if the user is valid" do
        it "returns a hash with the user name" do
          name = "foo"
          User.stubs(:find_or_create_from_google_token).returns(User.make(:name => name))
          get 'google_login', @args
          MultiJson.decode(response.body)["name"].should == name
        end

        describe "using created_at as a proxy for new user status" do
          it "returns a hash with isNewUser = false if the user is not new" do
            User.stubs(:find_or_create_from_google_token).returns(User.make(:created_at => Time.now - 600))
            get 'google_login', @args
            MultiJson.decode(response.body)["isNewUser"].should be_false
          end          

          it "returns a hash with isNewUser = true if the user is new" do
            User.stubs(:find_or_create_from_google_token).returns(User.make(:created_at => Time.now - 1))
            get 'google_login', @args
            MultiJson.decode(response.body)["isNewUser"].should be_true
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
            MultiJson.decode(response.body)["error"]["needsTerms"].should be_true
          end
        end  
      end
      
      context do
        before :each do
          User.stubs(:find_or_create_from_google_token).raises APIManager::Google::InvalidTokenError          
        end
        
        it_behaves_like "Ajax controller handling invalid Google tokens"
      end
      
      context do
        before :each do
          @err = StandardError.new
          User.stubs(:find_or_create_from_google_token).raises(@err)
        end
        
        it_behaves_like "Ajax controllers handling errors"
      end
    end
  end

  describe "POST 'google_populate_contacts'" do
    before :each do
      @url = "google_populate_contacts"
      @args = {}
    
      @u = User.make
      controller.stubs(:current_user).returns(@u)
    end      
  
    it_behaves_like "Ajax controller requiring a logged in user"
  
    it "populates the user's contacts" do
      @u.expects(:populate_google_contacts).returns({})
      get "google_populate_contacts", @args
    end
  
    it "returns the titleized buckets with counts" do
      @u.expects(:populate_google_contacts).returns({
        :my_first_car => [1, 2],
        :my_last_bike => [:a, :b, :c]
      })
      get "google_populate_contacts", @args
      MultiJson.decode(response.body).should include({"My First Car" => 2, "My Last Bike" => 3})
    end
  
    context do
      before :each do
        @u.stubs(:populate_google_contacts).raises(APIManager::Google::InvalidTokenError)
      end

      it_behaves_like "Ajax controller handling invalid Google tokens"
    end
    
    context do
      before :each do
        @err = StandardError.new
        @u.stubs(:populate_google_contacts).raises(@err)
      end
      
      it_behaves_like "Ajax controllers handling errors"
    end
  end
end
