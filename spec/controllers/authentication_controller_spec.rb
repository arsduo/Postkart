require 'spec_helper'

describe AuthenticationController do

  describe "GET 'google_callback'" do
    it "should be successful" do
      get 'google_callback'
      response.should be_success
    end
  end

end
