module MobileControllerExtensions
  
  MOBILE_VIEW_FOLDER = "mobile_views"
  
  def self.included(base)
    base.class_eval do
      before_filter :detect_mobile_flags
      before_filter :prepend_view_path_if_mobile
      helper_method :is_mobile_device?
      helper_method :mobile_mode?
    end
  end
  
  def mobile_mode?
    # flag in the session overrides mobile device, if present
    session[:mobile_view].nil? ? is_mobile_device? : session[:mobile_view]
  end
  
  def is_mobile_device?
    !!request.headers['X_MOBILE_DEVICE']
  end
  
  
  private 
 
  def detect_mobile_flags
    # we allow two parameters:
    # :desktop, to force mobile devices to render in desktop mode
    # :mobile,  to force mobile mode on desktop browsers

    # we manually set the session value to persist the setting
    # (leaving it nil by default, see mobile_mode?)
    session[:mobile_view] = false if params[:desktop]
    session[:mobile_view] = true if params[:mobile]

    # if we've set a flag, redirect to get rid of it so it doesn't mess up jqm
    # this would do two redirects if someone accessed ?mobile=1&desktop=1 (which they'd deserve)
    redirect_to params if params.delete(:mobile) || params.delete(:desktop)
  end

  def prepend_view_path_if_mobile
    if mobile_mode?
     logger.debug("View: MOBILE")
     prepend_view_path File.join(Rails.root, 'app', MOBILE_VIEW_FOLDER)
    end
  end
end