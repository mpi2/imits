
require 'pp'

class RootController < ApplicationController

  respond_to :html

  def index
    if user_signed_in?
      render 'root/index'
    else
      @table_1 = ReadOnlyIndexReport::get_new_impc_mouse_prod_attempts_table
      @table_2 = ReadOnlyIndexReport::get_new_impc_gc_mice_table
      @table_3 = ReadOnlyIndexReport::get_ikmc_production_statistics
      render 'open/root/index'
    end
  end

  def contactable_users_by_production_centre
    @users_by_production_centre = {}
    @centre_contact = {}

    Centre.all.each do |centre|
      @centre_contact[centre.name] = centre.contact_email;
    end

    User.where("active = true").order('users.name').includes(:production_centre).each do |user|
      if(user.is_contactable)
        @users_by_production_centre[user.production_centre.try(:name)] ||= []
        @users_by_production_centre[user.production_centre.try(:name)].push(user)
      end
    end

  end

  def users_by_production_centre
    authenticate_user!
    @users_by_production_centre = {}

    User.where("active = true").order('users.name').includes(:production_centre).each do |user|
      @users_by_production_centre[user.production_centre.try(:name)] ||= []
      @users_by_production_centre[user.production_centre.try(:name)].push(user)
    end
  end

  def consortia
    @consortia_production_centres = {}


    sql = <<-EOF
      SELECT DISTINCT consortia.name AS consortium_name, centres.name AS centre_name, centres.contact_name, centres.contact_email
      FROM consortia
      LEFT JOIN
      (mi_plans JOIN centres ON centres.id = mi_plans.production_centre_id) ON consortia.id = mi_plans.consortium_id
    EOF

    results = ActiveRecord::Base.connection.execute (sql)

    results.each do |rec|
      @consortia_production_centres[rec['consortium_name']] = [] unless @consortia_production_centres[rec['consortium_name']]
      @consortia_production_centres[rec['consortium_name']] << {:consortium_name=> rec['consortium_name'], :centre_name => rec['centre_name'], :contact_name => rec['contact_name'], :contact_email => rec['contact_email']}
    end
  end

  def debug_info
  end

  def public_dump
    file_path = File.join(Rails.application.config.paths['upload_path'].first, 'public_dump.sql.tar.gz')

    send_file file_path, :disposition => 'attachment'
  end

end
