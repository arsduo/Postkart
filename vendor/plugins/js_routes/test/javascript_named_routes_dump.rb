require 'rubygems'
require 'test/unit'
require 'action_controller'
require 'action_controller/test_process'

# initialization attempts to delete cached js under RAILS_ROOT
RAILS_ROOT = '/tmp'
require 'javascript_named_routes'

# initialize the plugin
require File.dirname(__FILE__) + '/../init'

# load the routes file from the cmd line
load ENV['routes']

module JavascriptNamedRoutes
  # don't try to cache the page under /public/javascripts
  ActionController::Base.perform_caching = false
  
  class RoutesControllerTest < ActionController::TestCase
    def test_dump_routes
      get :index
      puts @response.body
    end
  end
end
