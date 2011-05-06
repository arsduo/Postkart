Postkart::Application.routes.draw do

  # home
  get "home/user_data"
  
  # trip
  post "trip/create"
  get "trip/view"
  post "trip/send_card"

  # Authentication
  get "authentication/google_start"
  get "authentication/google_callback"
  post "authentication/google_login"
  post "authentication/google_populate_contacts"


  # OFFLINE
  offline = Rack::Offline.configure do
    public_path = Pathname.new(Rails.public_path)
    
    # need to refine this to more intelligently cache stuff
    Dir["#{public_path.to_s}/**/*"].each do |file|
      cache Pathname.new(file).relative_path_from(public_path) if File.file?(file)
    end

    fallback "authentication/google_start" => "/offline_login.html"
  end

  # browser manifest
  match "/application.manifest" => offline
  # to do: create smaller browser manifest
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # devise
  devise_for :users

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "home#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
