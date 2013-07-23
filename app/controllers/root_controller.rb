
require 'pp'

class RootController < ApplicationController

  respond_to :html

  def index
    if user_signed_in?
      render 'root/index'
    else
      @table_1 = ReadOnlyIndexReport::get_new_impc_mouse_prod_attempts_table
      @table_2 = ReadOnlyIndexReport::get_new_impc_gc_mice_table
      render 'open/root/index'
    end
  end

  def users_by_production_centre
    authenticate_user!
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

  def public_dump
    file_path = File.join(Rails.application.config.paths['upload_path'].first, 'public_dump.sql.tar.gz')

    send_file file_path, :disposition => 'attachment'
  end

end
