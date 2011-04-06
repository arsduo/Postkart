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
    it "returns :no_token => true if no token provided" do
      get 'google_login'
      JSON.parse(response.body)["no_token"].should be_true
    end
    
    context "with a token" do
      before :each do
        @args = {:access_token => "foo", :expires_in => 3600}
      end
      
      it "finds_or_creates a user from the token" do
        User.expects(:find_or_create_from_google_token).with(@args[:access_token]).returns(User.make)
        get 'google_login', @args
      end

      it "signs that user in" do
        u = User.make
        User.stubs(:find_or_create_from_google_token).returns(u)
        controller.expects(:sign_in).with(:user, u)
        get 'google_login', @args
      end      
      
      it "returns a hash with the user name" do
        name = "foo"
        User.stubs(:find_or_create_from_google_token).returns(User.make(:name => name))
        get 'google_login', @args
        JSON.parse(response.body)["name"].should == name
      end

      describe "using created_at as a proxy for new user status" do
        it "returns a hash with is_new_user = false if the user is not new" do
          User.stubs(:find_or_create_from_google_token).returns(User.make(:created_at => Time.now - 600))
          get 'google_login', @args
          JSON.parse(response.body)["is_new_user"].should be_false
        end    
      
        it "returns a hash with is_new_user = true if the user is new" do
          User.stubs(:find_or_create_from_google_token).returns(User.make(:created_at => Time.now - 1))
          get 'google_login', @args
          JSON.parse(response.body)["is_new_user"].should be_true
        end
      end
    end
  end
end
