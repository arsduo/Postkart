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
    @controller_name = "testing"
    @action_name = "act"
    Postkart::Application.routes.draw do
      get "#{@controller_name}/#{@action_name}", :controller => :testing, :action => :act 
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

    it "sets up a before_filter for detect_mobile_flags" do
      @mock_controller_class.stubs(:before_filter)
      @mock_controller_class.expects(:before_filter).with(:detect_mobile_flags)
      @mock_controller_class.send(:include, MobileControllerExtensions)
    end
    
    it "sets up a before_filter for prepend_view_path_if_mobile" do
      @mock_controller_class.stubs(:before_filter)
      @mock_controller_class.expects(:before_filter).with(:prepend_view_path_if_mobile)
      @mock_controller_class.send(:include, MobileControllerExtensions)
    end
  end
  
  # here's where we test the actual module functions
  describe "methods" do
    before :each do
      @url = @action_name
    end
    
    describe ".detect_mobile_flags" do
      context "mobile" do
        it "sets session[:mobile_view] = true if params[:mobile]" do
          get @url, :mobile => 1
          session[:mobile_view].should be_true
        end
        
        it "redirects to the page w/o the mobile flag if it's present" do
          params = HashWithIndifferentAccess.new(:mobile => 1, :foo => "bar", :controller => @controller_name, :action => @action_name)
          controller.expects(:redirect_to).with(params.dup.delete_if {|k, v| k.to_sym == :mobile})
          get @url, params
        end
      end

      context "desktop" do
        it "sets session[:mobile_view] = false if params[:desktop]" do
          get @url, :desktop => 1
          session[:mobile_view].should be_false
        end

        it "redirects to the page w/o the desktop flag if it's present" do
          params = HashWithIndifferentAccess.new(:desktop => 1, "foo" => "bar", :controller => @controller_name, :action => @action_name)
          controller.expects(:redirect_to).with(params.dup.delete_if {|k, v| k.to_sym == :desktop})
          get @url, params
        end
      end
    end

    describe ".prepend_view_path_if_mobile before_filter" do
      context "in desktop mode" do 
        it "does not add the MOBILE_VIEW_PATH to the view paths" do
          session[:mobile_view] = false
          get @url
          controller.view_paths.map(&:to_s).should_not include(File.join(Rails.root, 'app', MobileControllerExtensions::MOBILE_VIEW_FOLDER))
        end
      end
      
      context "in mobile mode" do 
        it "adds the MOBILE_VIEW_PATH to the view paths" do
          session[:mobile_view] = true
          get @url
          controller.view_paths.map(&:to_s).should include(File.join(Rails.root, 'app', MobileControllerExtensions::MOBILE_VIEW_FOLDER))
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