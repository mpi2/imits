class UsersController < Devise::RegistrationsController
  include ActionView::Helpers::TagHelper

  layout :layout_by_referer

  prepend_before_filter :authenticate_scope!, :only => [:show, :update]

  def show
    render_with_scope :edit
  end

  def index
    @users = User.all
    respond_with @users.to_json(:only => [:id, :name], :methods => [:production_centre_name, :filter_by_centre_name])
  end

  private

    def layout_by_referer
      targ_rep? ? 'targ_rep' : 'application'
    end

    def targ_rep?
      params[:redirect] == 'targ_rep'
    end

end
