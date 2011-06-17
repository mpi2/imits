class MiAttemptsController < ApplicationController

  respond_to :html, :json, :xml

  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html do
        @search_params = {
          :search_terms => []
        }

        if !params[:search_terms].blank?
          @search_params[:search_terms] = params[:search_terms].lines.collect(&:strip)
        end

        [:production_centre_id, :mi_attempt_status_id].each do |filter_attr|
          if !params[filter_attr].blank?
            @search_params[filter_attr] = params[filter_attr].to_i
          end
        end
      end

      format.xml { render :xml => MiAttempt.metasearch(cleaned_params).all }
      format.json { render :json => MiAttempt.metasearch(cleaned_params).all }
    end
  end

  def new
    @centres = Centre.all
    @mi_attempt = MiAttempt.new(
      :production_centre => current_user.production_centre,
      :distribution_centre => current_user.production_centre)
  end

  def create
    mi_attempt = MiAttempt.new(params[:mi_attempt])
    mi_attempt.updated_by = current_user
    mi_attempt.save

    respond_with mi_attempt do |format|
      format.html do
        flash[:notice] = 'MI Attempt created'
        redirect_to root_path
      end
    end
  end

  def show
    @centres = Centre.all
    @mi_attempt = MiAttempt.find(params[:id])
    respond_with @mi_attempt
  end

  def update
    @mi_attempt = MiAttempt.find(params[:id])
    @mi_attempt.attributes = params[:mi_attempt]
    @mi_attempt.updated_by = current_user

    if @mi_attempt.save
      flash[:notice] = 'MI attempt updated successfully'
    end

    respond_with @mi_attempt
  end

end
