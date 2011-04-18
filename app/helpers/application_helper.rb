module ApplicationHelper
  def google_auth_url
    APIManager::Google.auth_url.html_safe
  end

end
