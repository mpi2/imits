class UserSessionsController < ApplicationController
  def new
  end

  def create
    user = User.authenticate params[:username], params[:password]
    if user
      session[:current_username] = user.user_name
      redirect_to root_path
    else
      flash[:error] = 'Username or password was incorrect'
      redirect_to login_path
    end
  end
end
