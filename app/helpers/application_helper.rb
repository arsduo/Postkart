module ApplicationHelper
  def google_auth_url
    raw APIManager::Google.auth_url
  end

end
