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

  def consortia
    @consortia_production_centres = {}

    Consortium.includes(:mi_plans => :production_centre).each do |cons|
      production_centres = []
      cons.mi_plans.each do |mi_plan|
        production_centres.push(mi_plan.production_centre.try(:name))
      end
      @consortia_production_centres[cons.name] = production_centres.compact.uniq.sort
    end
  end

  def debug_info
  end

end
