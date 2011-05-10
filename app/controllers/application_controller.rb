class ApplicationController < ActionController::Base
  protect_from_forgery
  
  has_mobile_fu
  before_filter :set_mobile_status
  
  layout :set_layout
  
  private
  
  def set_layout
    is_mobile_device? ? "mobile" : "desktop"
  end
  
  def set_mobile_status
    session[:mobile_view] = true  if params[:mobile]
    session[:mobile_view] = false if params[:desktop]
  end
  
  def ensure_signed_in    
    render :json => {:error => {:loginRequired => true}} unless user_signed_in?
  end
  
  def send_exception_notification(exception)
    if Rails.env.production?
      # merge in our default options
      options = (request.env['exception_notifier.options'] ||= {})
      options.reverse_merge!(ExceptionNotifierOptions)
      ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
    end
  end
end
