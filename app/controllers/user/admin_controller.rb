class User::AdminController < ApplicationController

  before_filter :authenticate_user!

  before_filter do
    unless current_user.admin?
      redirect_to root_url, :alert => 'Unauthorized access detected!  This incident will be reported'
      Rails.logger.info "Unauthorized access detected by #{current_user.inspect}"
    end
  end

  def index
  end

  def transform
    sign_in(:user, User.find_by_email!(params[:user_email]))
    session[:masquerade] = true
    redirect_to user_path, :notice => 'Transformation complete'
  end

  def create_user
    @user = User.new(params[:user].merge(:password => 'password'))
    if @user.save
      sign_in(:user, @user)
      redirect_to user_path, :notice => "User with password 'password' created"
    else
      flash[:alert] = @user.errors.full_messages.join("<br/>").html_safe
      render :action => :index
    end
  end
end
