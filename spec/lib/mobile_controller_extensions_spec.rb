require 'spec_helper'

class TestingController < ApplicationController
  include MobileControllerExtensions
  def act
    render :text => ""
  end
end

describe TestingController do 
  include RSpec::Rails::ControllerExampleGroup
  before :all do
    Postkart::Application.routes.draw do
      get "testing/act", :controller => :testing, :action => :act 
    end    
  end
  
  after :all do
    # restore all routes
    Postkart::Application.reload_routes!
  end
   
  describe "on inclusion" do
    before :each do 
      class MiniMockController < ActionController::Base; end
      @mock_controller_class = MiniMockController
      @mock_controller_class.stubs(:helper_method)
    end
    
    it "sets up a helper method for is_mobile_device?" do
      @mock_controller_class.expects(:helper_method).with(:is_mobile_device?)
      @mock_controller_class.send(:include, MobileControllerExtensions)
    end

    it "sets up a helper method for is_mobile_device?" do
      @mock_controller_class.expects(:helper_method).with(:mobile_mode?)
      @mock_controller_class.send(:include, MobileControllerExtensions)
    end

    it "sets up a before_filter for setup_mobile" do
      @mock_controller_class.expects(:before_filter).with(:setup_mobile)
      @mock_controller_class.send(:include, MobileControllerExtensions)
    end
  end
  
  # here's where we test the actual module functions
  describe "methods" do
    before :each do
      @url = "act"
    end
    
    describe ".setup_mobile" do
      context "mobile" do
        it "sets session[:mobile_view] = true if params[:mobile]" do
          get @url, :mobile => 1
          session[:mobile_view].should be_true
        end

        it "adds the MOBILE_VIEW_PATH to the view paths" do
          get @url, :mobile => 1
          controller.view_paths.map(&:to_s).should include(File.join(Rails.root, 'app', MobileControllerExtensions::MOBILE_VIEW_FOLDER))
        end
      end

      context "desktop" do
        it "sets session[:mobile_view] = false if params[:desktop]" do
          get @url, :desktop => 1
          session[:mobile_view].should be_false
        end

        it "does not add the MOBILE_VIEW_PATH to the view paths" do
          get @url, :desktop => 1
          controller.view_paths.map(&:to_s).should_not include(File.join(Rails.root, 'app', MobileControllerExtensions::MOBILE_VIEW_FOLDER))
        end
      end
    end

    describe ".mobile_mode?" do
      context "true results" do
        it "returns true if it's a mobile device and session[:mobile_view] is nil" do
          session[:mobile_view] = nil
          controller.stubs(:is_mobile_device?).returns(true)
          controller.mobile_mode?.should be_true
        end
      
        it "returns true if it's it's a mobile device and session[:mobile_view] is true" do
          session[:mobile_view] = true
          controller.stubs(:is_mobile_device?).returns(true)
          controller.mobile_mode?.should be_true
        end
      
        it "returns true if it's it's a non-mobile device and session[:mobile_view] is true" do
          session[:mobile_view] = true
          controller.stubs(:is_mobile_device?).returns(false)
          controller.mobile_mode?.should be_true
        end
      end
      
      context "false results" do
        it "returns false if it's a non-mobile device and session[:mobile_view] is nil" do
          session[:mobile_view] = nil
          controller.stubs(:is_mobile_device?).returns(false)
          controller.mobile_mode?.should be_false
        end
      
        it "returns false if session[:mobile_view] is false, even if it's it's a mobile device" do
          session[:mobile_view] = false
          controller.stubs(:is_mobile_device?).returns(true)
          controller.mobile_mode?.should be_false
        end
      
        it "returns false if session[:mobile_view] is false and it's a non-mobile device" do
          session[:mobile_view] = false
          controller.stubs(:is_mobile_device?).returns(false)
          controller.mobile_mode?.should be_false
        end
      end
    end

    describe ".is_mobile_device?" do
      it "returns true if Rack::MobileDetect sets the header" do
        request.stubs(:headers).returns({'X_MOBILE_DEVICE' => true})
        controller.is_mobile_device?.should be_true
      end
      
      it "returns false if Rack::MobileDetect does not set the header" do
        request.stubs(:headers).returns({})
        controller.is_mobile_device?.should be_false
      end
    end
  end  
end