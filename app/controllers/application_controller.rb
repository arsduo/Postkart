class ApplicationController < ActionController::Base
  protect_from_forgery
  
  private
  
  def send_exception_notification(exception)
    if Rails.env.production?
      # merge in our default options
      options = (request.env['exception_notifier.options'] ||= {})
      options.reverse_merge!(ExceptionNotifierOptions)
      ExceptionNotifier::Notifier.exception_notification(request.env, exception).deliver
    end
  end
end
