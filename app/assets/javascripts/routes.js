var Routes = (function(){
  return {
    trips_view_path: function() {return "/trips/view";},
    trips_create_path: function() {return "/trips/create";},
    root_path: function() {return "/";},
    trips_send_card_path: function() {return "/trips/send_card";},
    authentication_google_callback_path: function() {return "/authentication/google_callback";},
    authentication_google_login_path: function() {return "/authentication/google_login";},
    authentication_google_populate_contacts_path: function() {return "/authentication/google_populate_contacts";},
    jammit_path: function(package, extension) {return "/assets/"+package+"."+extension;},
    rails_info_properties_path: function() {return "/rails/info/properties";}
  }
})();