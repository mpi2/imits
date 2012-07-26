# encoding: utf-8

class SubProjectsController < ApplicationController

  def create
      @sub_project = MiPlan::SubProject.new(params[:mi_plan_sub_project])
      if @sub_project.valid? and !@sub_project.name.empty?
        @sub_project.save
        flash[:notice] = "Sub-project '#{@sub_project.name}' created"
      elsif !@sub_project.name.empty?
        flash[:alert] = "Sub-project '#{@sub_project.name}' already exists"
      end
   redirect_to :sub_projects
  end

  def destroy
    @sub_project = nil

    if !params[:id].blank?
      @sub_project = MiPlan::SubProject.find_by_id(params[:id])
      if @sub_project.miplan?
        @sub_project = nil
      end
    end

    if !@sub_project.nil?
      @sub_project.destroy
      flash[:notice] = "Successfully deleted sub-project '#{@sub_project.name}'"
    else
      flash[:alert] = "Sub-project '#{@sub_project.name}' Could not be deleted"
    end
    redirect_to :sub_projects
  end

  def index
    @sub_project = MiPlan::SubProject.all
    @sub_project_new = MiPlan::SubProject.new
    respond_to do |format|
      format.html
    end
  end
end
