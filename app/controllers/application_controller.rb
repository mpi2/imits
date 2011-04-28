class ApplicationController < ActionController::Base
  protect_from_forgery

  private

  def authenticate
    if ! current_user
      redirect_to login_path
    end
  end

  helper_method :current_user

  def current_user
    return nil # TODO User.find_by_user_name session[:current_username]
  end
end
