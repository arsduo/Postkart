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

    describe "for contacts" do
      it "orders the contact data in ascending order" do
        # it would be better to set up some fake records
        # and check the output
        # but this will more or less work (or fail if I change it)
        contacts = []
        @user.expects(:contacts).returns(contacts)
        contacts.expects(:asc).returns(contacts)
        contacts.stubs(:where).returns(contacts)
        get 'user_data'
      end
    
      it "only gets records newer than the provided parameter" do
        time = 1344
        contacts = []
        @user.expects(:contacts).returns(contacts)
        contacts.stubs(:asc).returns(contacts)
        contacts.expects(:where).with(:updated_at.gte => Time.at(time)).returns(contacts)
        get 'user_data', :since => time
      end
      
      it "sends the the contacts' client_json down as contactsByName" do
        contacts = [Contact.make, Contact.make]
        @user.stubs(:contacts).returns(contacts)
        contacts.stubs(:where).returns(contacts)
        contacts.stubs(:asc).returns(contacts)

        get 'user_data'
        # we have to parse like this to eliminate objects like BSON IDs
        JSON.parse(response.body)["contactsByName"].should == JSON.parse(contacts.map {|c| c.client_json}.to_json)
      end
    end
    
    describe "for trips" do
      it "only gets records newer than the provided parameter" do
        time = 1344
        trips = []
        @user.stubs(:trips).returns(trips)
        trips.stubs(:asc).returns(trips)
        trips.expects(:where).with(:updated_at.gte => Time.at(time)).returns(trips)
        get 'user_data', :since => time
      end

      it "sorts the trips by ID" do
        trips = []
        @user.stubs(:trips).returns(trips)
        trips.expects(:asc).returns(trips)
        trips.stubs(:where).returns(trips)

        get 'user_data'        
      end
      
      it "sends the the trips' client_json down as tripsByDate" do
        trips = [Trip.make, Trip.make]
        @user.stubs(:trips).returns(trips)
        trips.stubs(:asc).returns(trips)
        trips.stubs(:where).returns(trips)

        get 'user_data'
        # we have to parse like this to eliminate objects like BSON IDs
        JSON.parse(response.body)["tripsByDate"].should == JSON.parse(trips.map {|t| t.client_json}.to_json)
      end
    end
  end
end
