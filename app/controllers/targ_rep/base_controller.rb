class TargRep::BaseController < ActionController::Base
  protect_from_forgery

  layout 'targ_rep'
  clear_helpers

  before_filter :authenticate_user!

  def authorize_admin_user!
    if current_user.try(:admin?) != true

      respond_to do |format|
        format.html do
          flash[:alert] = 'Access to restricted area detected - this incident has been logged'
          redirect_to root_path
        end

        format.json do
          render :json => {'error' => 'Access to restricted area detected - this incident has been logged' }
        end
      end

      Rails.logger.info 'Unauthorized access detected'
    end
  end
  protected :authorize_admin_user!

end