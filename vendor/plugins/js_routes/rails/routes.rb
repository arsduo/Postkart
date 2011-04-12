if defined?(Rails::Application)
  # Rails3 routes
  Rails.application.routes.draw do
    match "/#{JavascriptNamedRoutes.package_path}/:package.:extension",
      :to => 'JavascriptNamedRoutesController#package', :as => :jammit, :constraints => {
        # A hack to allow extension to include "."
        :extension => /.+/
      }
  end
end
