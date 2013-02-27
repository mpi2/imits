class Admin::BaseController < ApplicationController

  before_filter :authenticate_user!

  before_filter do
    unless current_user.admin?
      redirect_to root_url, :alert => 'Unauthorized access detected!  This incident will be reported'
      Rails.logger.info "Unauthorized access detected by #{current_user.inspect}"
    end
  end

  def history
    @resource = controller_name.classify.constantize.find(params[:id])
    render :template => '/shared/history'
  end

end
