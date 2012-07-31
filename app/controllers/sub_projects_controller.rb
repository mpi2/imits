# encoding: utf-8

class SubProjectsController < ApplicationController

  def create
    @sub_project = MiPlan::SubProject.new(params[:mi_plan_sub_project])
    if @sub_project.valid?
      @sub_project.save
      flash[:notice] = "Sub-project '#{@sub_project.name}' created"
    else
      flash[:alert] = "#{@sub_project.errors[:name].join}"
    end
    redirect_to :sub_projects
  end

  def destroy
    @sub_project = nil
    old_name = ''
    if !params[:id].blank?
      @sub_project = MiPlan::SubProject.find_by_id(params[:id])
      old_name = @sub_project.name
      if @sub_project.has_mi_plan?
        @sub_project = nil
      end
    end

    if !@sub_project.nil?
      @sub_project.destroy
      flash[:notice] = "Successfully deleted sub-project '#{@sub_project.name}'"
    else
      flash[:alert] = "Sub-project '#{old_name}' Could not be deleted"
    end
    redirect_to :sub_projects
  end

  def index
    @sub_project = MiPlan::SubProject.find(:all, :order => "name")
    @sub_project_new = MiPlan::SubProject.new
    respond_to do |format|
      format.html
      format.json { render :json => @sub_project}
    end
  end
end
