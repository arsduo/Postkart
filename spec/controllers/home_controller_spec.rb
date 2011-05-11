require 'spec_helper'

describe HomeController do

  render_views

  describe "filters and such" do
    describe "mobile/desktop" do
      before :each do
        @url = "index"
      end

      context "mobile" do
        it "sets session[:mobile_view] = true if params[:mobile]" do
          get @url, :mobile => 1
          session[:mobile_view].should be_true
        end

        it "renders with the mobile template"
      end

      context "desktop" do
        it "sets session[:mobile_view] = false if params[:desktop]" do
          get @url, :desktop => 1
          session[:mobile_view].should be_false
        end

        it "renders with the desktop template"
      end
    end
  end

  describe ".user_data" do
    before :each do
      @url = "user_data"
      @user = User.make
      controller.stubs(:current_user).returns(@user)
    end

    it_should_behave_like "Ajax controller requiring a logged in user"

    it "sends the user client_json as :user" do
      get 'user_data'
      JSON.parse(response.body)["user"].should == JSON.parse(@user.client_json.to_json)
    end

    it "orders the contact data in ascending order" do
      # it would be better to set up some fake records
      # and check the output
      # but this will more or less work (or fail if I change it)
      contacts = []
      @user.expects(:contacts).returns(contacts)
      contacts.expects(:asc).returns(contacts)
      get 'user_data'
    end

    it "sends the the contacts' client_json down as contactsByName" do
      contacts = [Contact.make, Contact.make]
      @user.stubs(:contacts).returns(contacts)
      contacts.stubs(:asc).returns(contacts)

      get 'user_data'
      # we have to parse like this to eliminate objects like BSON IDs
      JSON.parse(response.body)["contactsByName"].should == JSON.parse(contacts.map {|c| c.client_json}.to_json)
    end
  end
end
