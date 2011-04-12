module JavascriptNamedRoutes
  class RoutesController < ActionController::Base
    caches_page :index
  
    def index
      respond_to do |format|
        format.js do
          collect_routes
        end
      end
    end
  
    private
  
    def route_info(name, route)
      segments = []
      keys     = []
    
      route.segments.each do |segment|
        case segment
          when ActionController::Routing::OptionalFormatSegment
            break
          when ActionController::Routing::DynamicSegment
            segments << '_'
            keys     << segment.key.to_json
          else
            segments << segment.value.to_json
        end
      end
    
      segments.pop if segments.last == '/'.to_json
    
      name     = "#{name}_path".camelize(:lower).to_json
      segments = '[' + segments.join(', ') + ']'
      keys     = '[' + keys.join(', ') + ']'
    
      [name, segments, keys]
    end
  
    def collect_routes
      routes = ActionController::Routing::Routes.named_routes
      @route_data = routes.names.sort_by(&:to_s).collect do |name|
        route_info(name, routes[name])
      end
    end
  end
end

# make this available as a top-level controller
# again, patterned after Jammit
::JavascriptNamedRoutesController = JavascriptNamedRoutes::Controller