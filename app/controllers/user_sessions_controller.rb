class UserSessionsController < ApplicationController
  def new
  end

  def create
    user = User.authenticate params[:username], params[:password]
    if user
      session[:current_username] = user.user_name
      redirect_to root_path, :flash => {:notice => "Hello #{user.first_name}"}
    else
      redirect_to login_path, :flash => {:error => 'Username or password was incorrect'}
    end
  end

  def destroy
    session[:current_username] = nil
    redirect_to login_path, :notice => 'You have been logged out'
  end
end
