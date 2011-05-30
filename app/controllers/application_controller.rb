class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :setup_dev if Rails.env.development?
  before_filter :detect_contact_reload
  
  include MobileControllerExtensions

  private

  def detect_contact_reload
    if params.delete(:reloadData)
      # set the reload flag, then get rid of the extra URL flag to avoid confusing jQM
      flash[:reloadData] = true
      redirect_to params
    end
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
  
  def setup_dev
    if Rails.env.development? && params[:pow]
      sign_in(User.first)
      redirect_to root_path   
    end
  end
end
