# encoding: utf-8

class PhenotypingProductionsController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def create
    @phenotyping_production =  Public::PhenotypingProduction.new(params[:phenotyping_production])
#    @phenotyping_production.updated_by = current_user
    return unless authorize_user_production_centre(@phenotyping_production)
    return if empty_payload?(params[:phenotyping_production])

    respond_with @phenotyping_production do |format|
      format.json do
        if @phenotyping_production.valid? && user_is_allowed_to_update_phenotyping_dataflow_fields?(@phenotyping_production)
          @phenotyping_production.save
          render :json => @phenotyping_production
        else
          render :json => @phenotyping_production.errors.messages
        end
      end
    end
  end


  def update
    @phenotyping_production =  Public::PhenotypingProduction.find(params['id'])

    return if @phenotyping_production.blank?
    return unless authorize_user_production_centre(@phenotyping_production)
    return if empty_payload?(params[:phenotyping_production])

    @phenotyping_production.update_attributes(params[:phenotyping_production]) if user_is_allowed_to_update_phenotyping_dataflow_fields?(@phenotyping_production)

    respond_with @phenotyping_production do |format|
      format.json do
        if @phenotyping_production.valid? && user_is_allowed_to_update_phenotyping_dataflow_fields?(@phenotyping_production)
          render :json => @phenotyping_production
        else
          render :json => @phenotyping_production.errors.messages
        end
      end
    end
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
