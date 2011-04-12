require 'rubygems'
require 'tempfile'
require 'test/unit'
require 'action_controller'
require 'action_controller/test_process'

# initialization attempts to delete cached js under RAILS_ROOT
RAILS_ROOT = '/tmp'
require 'javascript_named_routes'

# initialize the plugin
require File.dirname(__FILE__) + '/../init'

module JavascriptNamedRoutes
  class RoutesControllerTest < ActionController::TestCase
    
    # a simple two-level resource controller
    
    ActionController::Routing::Routes.draw do |map|
      map.resources :users do |users|
        users.resources :accounts
      end
      
      map.javascript_named_routes
    end
    
    def test_action_success
      get :index
      assert_response :success
    end
    
    # don't try to cache the page under /public/javascripts
    ActionController::Base.perform_caching = false
    
    # test that the following named routes generated the correct route definition in routes.js
    
    [
      '"usersPath":route(["/","users"],[])',
      '"userPath":route(["/","users","/",_],["id"])',
      '"editUserPath":route(["/","users","/",_,"/","edit"],["id"])',
      '"userAccountsPath":route(["/","users","/",_,"/","accounts"],["user_id"])',
      '"userAccountPath":route(["/","users","/",_,"/","accounts","/",_],["user_id","id"])',
      '"editUserAccountPath":route(["/","users","/",_,"/","accounts","/",_,"/","edit"],["user_id","id"])'
    ].each do |expected|
      route_name = expected.match(/^"(\w+)"/).captures.first.underscore
      define_method("test_js_generation_#{route_name}") do
        help_test_js_generation(expected)
      end
    end
    
    def help_test_js_generation(expected)
      get :index
      body = @response.body.gsub(/ +/, '')
      assert body.include?(expected), "@response.body should contain <#{expected}>"
    end
    
    # set $RHINO_HOME to a directory containing js.jar to run these tests
    if ENV['RHINO_HOME']
      
      # test that the following named routes evaluate to the correct URL on the JS side
      
      # For each named route w/ args in the list, convert it into the corresponding JS expr -
      # e.g. [:users_path, 123, {:foo => 42}] becomes Routes.usersPath(123,{"foo":42}).  Then
      # generate a test method which invokes the route helper - users_path(123, :foo => 42) -
      # on the Rails side, and verifies that the results are equal.
      
      [
        [:users_path],
        [:users_path, {:format => 'xml'}],
        [:user_path, 123],
        [:user_path, 123, {:foo => 42}],
        [:user_path, {:id => 123}],
        [:edit_user_path, 123],
        [:edit_user_path, {:id => 123}],
        [:user_accounts_path, 123],
        [:user_account_path, 123, 456],
        [:user_account_path, {:id => 123, :user_id => 456}],
        [:edit_user_account_path, 123, 456],
        [:edit_user_account_path, 123, 456, {:foo => 42}]
      ].each do |route_args|
        route_name = route_args.shift
        
        # generate a test name from the route name and args 
        test_name = "test_js_route_#{route_name}"
        test_name += "_#{route_args}" if !route_args.empty?
        
        # camelize the route name and convert any args to JSON
        # to generate the expr that will be evaluated by OSA
        js_name = route_name.to_s.camelize(:lower)
        js_args = route_args.collect(&:to_json)
        js_expr = "Routes.#{js_name}(#{js_args.join(',')})"
        
        define_method(test_name) do
          # get the expected value by invoking the Rails route helper
          expected = send(route_name, *route_args)
          help_test_js_route(js_expr, expected)
        end
        
        def test_js_route_with_relative_url_root
          ActionController::Base.relative_url_root = '/path/to/my/subdir'
          help_test_js_route('Routes.userPath(123)', '/path/to/my/subdir/users/123')
        end
      end
    else
      warn "Skipping JavaScript tests, please install Rhino and set $RHINO_HOME"
    end
    
    def help_test_js_route(expr, expected)
      get :index
      
      # eval the routes file followed by the expression we want to evaluate
      tmp = Tempfile.new('routejs')
      tmp << @response.body
      tmp << 'print(' << expr << ')'
      tmp.close
      
      result = `java -jar $RHINO_HOME/js.jar #{tmp.path}`
      assert_equal expected, result.chomp
      tmp.close!
    end
  end
end
