require 'spec_helper'

describe APIManager do  
  class TestAPIManager < APIManager
    # allow initialization
    def initialize; end
  end
  
  describe ".new" do 
    it "throws an exception because you can't instantiate the base class directly" do
      expect {APIManager.new("token")}.to raise_exception(StandardError)
    end
  end
  
  describe ".service_name" do
    it "throws an exception if it's not overridden in the subclass" do
      expect {TestAPIManager.new("token").service_name}.to raise_exception(StandardError)
    end
  end
  
  describe ".make_request" do
    before :each do
      @mgr = TestAPIManager.new
      @typhoeus_response = Typhoeus::Response.new(:body => "[]")
    end
    
    it "makes a Typhoeus get request to the provided url" do
      url = "foobar"
      Typhoeus::Request.expects(:get).with(url, anything).returns(@typhoeus_response)
      @mgr.make_request(url)
    end
    
    it "makes a Typhoeus get request with the provided params" do
      params = {:a => 2}
      Typhoeus::Request.expects(:get).with(anything, :params => params).returns(@typhoeus_response)
      @mgr.make_request("foo", params)
    end
    
    it "merges any additional info into the Typhoeus arguments" do
      params = {:a => 2}
      options = {:Authorization => "foo"}
      Typhoeus::Request.expects(:get).with(anything, {:params => params}.merge(options)).returns(@typhoeus_response)
      @mgr.make_request("foo", params, options)
    end
    
    
    it "should retry if a Timeout occurs" do
      tries = sequence("typhoeus tries")
      Typhoeus::Request.expects(:get).in_sequence(tries).raises(Timeout::Error)
      Typhoeus::Request.expects(:get).in_sequence(tries).returns(@typhoeus_response)
      @mgr.make_request("foo")
    end

    it "passes on the error if it times out twice" do
      Typhoeus::Request.expects(:get).twice.raises(Timeout::Error)
      @mgr.stubs(:service_name).returns("APIManager Test")
      expect {@mgr.make_request("foo")}.to raise_exception(Timeout::Error)
    end
    
    it "JSON.parses the body of the response" do
      body = "[]"
      response = Typhoeus::Response.new(:body => body)
      Typhoeus::Request.expects(:get).with(anything, anything).returns(response)
      JSON.expects(:parse).with(body)
      @mgr.make_request("foo")
    end
  end
end