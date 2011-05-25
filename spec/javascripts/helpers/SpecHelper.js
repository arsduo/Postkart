// mock JST
JST = {
  google_start: function() {},
  trip_contact: function() {},
  mobile_trip_contact: function() {}
}

// mock jQuery mobile
$.mobile = {
  changePage: function() {}
}

$(document).ready(function() {
  // make jQuery do all its tests synchronously
  // otherwise we have to use Jasmine's waits fn
  // so the Jasmine spies, etc. are still available
  jQuery.ajaxSettings.async = false;
  // turn off Mockjax logging
  $.mockjaxSettings.log = function() {};
})
