# encoding: utf-8

class PhenotypingProductionsController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def create
    render :json => {
      'error' => 'Phenotype_attempts cannot be created or modified in iMits anymore. Please visit the new tracking system webpage www.gentar.org/tracker/'
    }, :status => 401
    return true
  end


  def update
    render :json => {
      'error' => 'Phenotype_attempts cannot be created or modified in iMits anymore. Please visit the new tracking system webpage www.gentar.org/tracker/'
    }, :status => 401
    return true
  end

  def show
    @phenotyping_production = Public::PhenotypingProduction.find(params[:id])
    respond_with @phenotyping_production do |format|
      format.json do
        render :json => @phenotyping_production
      end
    end
  end

  def colony_name
    @phenotyping_production = Public::PhenotypingProduction.find_by_colony_name(params[:colony_name])
    respond_with @phenotyping_production do |format|
      format.json do
        render :json => @phenotyping_production
      end
    end
  end

  def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'id asc', Public::PhenotypingProduction, :public_search, false)
      end
    end
  end

  def user_is_allowed_to_update_phenotyping_dataflow_fields?(phenotyping_production)

    if phenotyping_production.changes.has_key?(:phenotyping_started) && current_user.allowed_to_update_phenotyping_data_flow_fields
      flash.now[:alert] = 'Phenotype attempt could not be updated - Please do not update Phenotyping Started'
      return false
    end
    if phenotyping_production.changes.has_key?(:phenotyping_complete) && current_user.allowed_to_update_phenotyping_data_flow_fields
      flash.now[:alert] = 'Phenotype attempt could not be updated - Please do not update Phenotyping Complete'
      return false
    end
    if phenotyping_production.changes.has_key?(:late_adult_phenotyping_started) && current_user.allowed_to_update_phenotyping_data_flow_fields
      flash.now[:alert] = 'Phenotype attempt could not be updated - Please do not update Late Adult Phenotyping Started'
      return false
    end
    if phenotyping_production.changes.has_key?(:late_adult_phenotyping_complete) && current_user.allowed_to_update_phenotyping_data_flow_fields
      flash.now[:alert] = 'Phenotype attempt could not be updated - Please do not update Late Adult Phenotyping Complete'
      return false
    end
    if phenotyping_production.changes.has_key?(:ready_for_website) && current_user.allowed_to_update_phenotyping_data_flow_fields
      flash.now[:alert] = 'Phenotype attempt could not be updated - Please do not update Ready For Website date'
      return false
    end
    return true
  end
  private :user_is_allowed_to_update_phenotyping_dataflow_fields?
end
