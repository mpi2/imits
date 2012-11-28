class TargRep::BaseController < ActionController::Base
  protect_from_forgery

  layout 'targ_rep'
  clear_helpers

  helper 'targ_rep/alleles', 'targ_rep/application'

  before_filter :authenticate_user!

  def authorize_admin_user!
    unless current_user.admin?
      respond_to do |format|
        format.html do
          flash[:alert] = 'Access to restricted area detected - this incident has been logged'
          redirect_to root_path
        end

        format.json do
          render :json => {'error' => 'Access to restricted area detected - this incident has been logged' }, :status => 302
        end
      end

      return false
    end
  end
  protected :authorize_admin_user!

end