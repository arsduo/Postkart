class ApplicationController < ActionController::Base
  protect_from_forgery

  has_mobile_fu
  before_filter :setup_mobile

  private

  def setup_mobile
    # we allow two parameters:
    # :desktop, to force mobile devices to render in desktop mode
    # :mobile,  to force mobile mode on desktop browsers

    # we manually set the session value to persist the setting
    # (since mobile_fu only changes it if it's nil)
    session[:mobile_view] = false if params[:desktop]
    session[:mobile_view] = true if params[:mobile]

    # setting the session persists the setting
    # but for desktops, we still have to force mobile if desired
    set_device_type(session[:mobile_view])
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
