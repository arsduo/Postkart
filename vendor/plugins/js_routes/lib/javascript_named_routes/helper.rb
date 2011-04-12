module JavascriptNamedRoutes
  module Helper
    html_safe
    
  end
end

# Include the JavascriptNamedRoutes asset helper in all views
::ActionView::Base.send(:include, JavascriptNamedRoutes::Helper)
