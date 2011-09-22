class RootController < ApplicationController

  respond_to :html

  before_filter :authenticate_user!

  def index
  end

  def users_by_production_centre
    @users_by_production_centre = {}

    User.order('users.name').includes(:production_centre).each do |user|
      @users_by_production_centre[user.production_centre.name] ||= []
      @users_by_production_centre[user.production_centre.name].push(user)
    end
  end
end
