require 'spec_helper'

describe ApplicationController do
  it "includes MobileControllerExtensions" do
    controller.class.included_modules.should include MobileControllerExtensions
  end
end
