class TargRep::BaseController < ActionController::Base
  protect_from_forgery

  layout 'targ_rep'
  clear_helpers

  helper 'targ_rep/alleles', 'targ_rep/application'

  before_filter :authenticate_user!

  require 'allele_image'

  after_filter :store_location

  def store_location
    # store last url as long as it isn't a /users path
    session[:previous_url] = request.fullpath
  end

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

  def empty_payload?(payload)
    if payload.blank? || payload.is_a?(Hash) && payload.empty?
      render :json => {
        'error' => 'Your JSON payload is empty.'
      }, :status => 400
      return true
    end

    return false
  end
  protected :empty_payload?

end