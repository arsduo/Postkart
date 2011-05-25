class ApplicationController < ActionController::Base
  protect_from_forgery

  include MobileControllerExtensions

  private

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
