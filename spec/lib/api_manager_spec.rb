require 'spec_helper'

describe APIManager do  
  describe ".new" do 
    it "throws an exception because you can't instantiate the base class directly" do
      expect {APIManager.new("token")}.to raise_exception(StandardError)
    end
  end
  
  describe "#make_request" do
    class TestAPIManager < APIManager
      # allow initialization
      def initialize; end
    end

    before :each do
      @mgr = TestAPIManager.new
    end
    
    it "should make a Typhoeus get request to the provided url" do
      url = "foobar"
      Typhoeus::Request.expects(:get).with(url, anything).returns(Typhoeus::Response.new(:body => "[]"))
      @mgr.make_request(url)
    end
    
    it "should make a Typhoeus get request to the provided url" do
      params = {:a => 2}
      Typhoeus::Request.expects(:get).with(anything, :params => params).returns(Typhoeus::Response.new(:body => "[]"))
      @mgr.make_request("foo", params)
    end
    
    it "should JSON.parse the body of the response" do
      body = "[]"
      response = Typhoeus::Response.new(:body => body)
      Typhoeus::Request.expects(:get).with(anything, anything).returns(response)
      JSON.expects(:parse).with(body)
      @mgr.make_request("foo")
    end
  end
end