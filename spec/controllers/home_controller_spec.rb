require 'spec_helper'

describe HomeController do

  render_views

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
