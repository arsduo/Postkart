module JavascriptNamedRoutes
  DEFAULT_PACKAGE_PATH = "js_routes"
  DEFAULT_NAMESPACE = "Routes"
  
  @package_path = DEFAULT_PACKAGE_PATH
  @namespace = DEFAULT_NAMESPACE

  
  module MapperExtensions
    def javascript_named_routes
      @set.add_route 'javascripts/routes.js', :controller => 'javascript_named_routes/routes'
    end
  end
  
  module ViewHelperExtensions
    def javascript_named_routes
      javascript_include_tag 'routes'
    end
  end
  
  # inject the mapper and view extensions
  ActionController::Routing::RouteSet::Mapper.send :include, MapperExtensions
  ActionView::Base.send :include, ViewHelperExtensions
  
  # make sure the cached file is removed on startup
  begin
    File.delete(RAILS_ROOT + '/public/javascripts/routes.js')
  rescue Errno::ENOENT => e
  end
end

require 'javascript_named_routes/controller'