class RootController < ApplicationController

  respond_to :html

  before_filter :authenticate_user!

  def index
    redirect_to mi_attempts_path('q[production_centre_name]' => current_user.production_centre.name)
    flash.keep
  end
end
