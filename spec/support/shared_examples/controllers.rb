shared_examples_for "Ajax controllers handling errors" do
  it "returns {:error => {:otherError => true}}" do
    get @url, @args
    MultiJson.decode(response.body)["error"]["otherError"].should be_true
  end
  
  it "sends a notification" do 
    controller.expects(:send_exception_notification).with(@err)
    get @url, @args
  end
end

shared_examples_for "Ajax controller handling invalid Google tokens" do
  it "returns :invalid_token => true" do
    get @url, @args
    MultiJson.decode(response.body)["error"]["invalidToken"].should be_true
  end
  
  it "returns a redirect to google_start the first time" do
    get @url, @args
    MultiJson.decode(response.body)["error"]["retry"].should be_true
  end
  
  it "does not return a redirect on subsequent errors" do
    get @url, @args
    get @url, @args
    MultiJson.decode(response.body)["error"]["retry"].should be_nil
  end
  
  it "sends an exception if there have been five or more failed retry attempts overall" do
    # breaking encapsulation!!!  warning!  warning!  whoooop whoooop whoooop whooop!  
    controller.class.send(:class_variable_set, :@@invalid_tokens, 0)
    controller.class.send(:class_variable_set, :@@invalid_token_error_sent, false)
    controller.expects(:send_exception_notification).with(kind_of APIManager::Google::InvalidTokenError)
    10.times { get @url, @args }
  end
end

shared_examples_for "Ajax controller requiring a logged in user" do
  before :each do
    controller.stubs(:user_signed_in?).returns(false)
  end
  
  it "returns an error message if the user isn't signed in" do
    get @url, @args
    MultiJson.decode(response.body)["error"]["loginRequired"].should be_true
  end
end
