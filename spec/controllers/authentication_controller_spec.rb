require 'spec_helper'

describe AuthenticationController do
  render_views
  
  describe "GET 'google_callback'" do
    it "is successful" do
      get 'google_callback'
      response.should be_success
    end
  end
  
  describe "POST 'google_login'" do
    it "returns :noToken => true if no token provided"# do
#      get 'google_login'
#      JSON.parse(response.body)["noToken"].should be_true
#    end
    
    context "with a token" do
      before :each do
        @args = {:access_token => "foo", :expires_in => 3600}
      end
      
      it "finds_or_creates a user from the token" do
        User.expects(:find_or_create_from_google_token).with(@args[:access_token]).returns(User.make)
        get 'google_login', @args
      end

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
      
      it "returns a hash of validation errors if they occur"

      shared_examples_for "signing the user in" do
        it "executes sign-in" do
          @u ||= User.make
          User.stubs(:find_or_create_from_google_token).returns(@u)
          controller.expects(:sign_in).with(:user, @u)
          get 'google_login', @args
        end
      end
      
      context "for users who've previously accepted the terms" do
        it_behaves_like "signing the user in"
      end
      
      context "for users who just accepted the terms" do
        before :each do
          @args.merge!(:acceptedTerms => true)
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
  end
end
