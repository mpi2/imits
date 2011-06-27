class RootController < ApplicationController

  respond_to :html

  before_filter :authenticate_user!

  def index
    redirect_to mi_attempts_path(:production_centre_id => current_user.production_centre.id)
  end
end
