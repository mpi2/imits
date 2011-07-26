# encoding: utf-8

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

      format.xml { render :xml => data_for_serialized }
      format.json { render :json => data_for_serialized }
    end
  end

  def data_for_serialized
    params.delete(:per_page) if params[:per_page].blank? or params[:per_page].to_i == 0
    MiAttempt.metasearch(cleaned_params).paginate(:page => params[:page], :per_page => params[:per_page] || 20)
  end
  private :data_for_serialized

  def new
    set_centres_and_consortia
    @mi_attempt = MiAttempt.new(
      :production_centre => current_user.production_centre,
      :distribution_centre => current_user.production_centre,
      :consortium => current_user.consortium
    )
  end

  def create
    @mi_attempt = MiAttempt.new(params[:mi_attempt])
    @mi_attempt.updated_by = current_user
    @mi_attempt.production_centre ||= current_user.production_centre
    @mi_attempt.consortium ||= current_user.consortium
    if @mi_attempt.save
      flash[:notice] = 'Micro-injection attempt created'
    else
      flash.now[:alert] = 'Micro-injection could not be created - please check the values you entered'
      set_centres_and_consortia
    end

    respond_with @mi_attempt
  end

  def show
    set_centres_and_consortia
    @mi_attempt = MiAttempt.find(params[:id])
    respond_with @mi_attempt
  end

  def update
    @mi_attempt = MiAttempt.find(params[:id])
    @mi_attempt.attributes = params[:mi_attempt]
    @mi_attempt.updated_by = current_user

    if @mi_attempt.save
      flash.now[:notice] = 'MI attempt updated successfully'
    end

    respond_with @mi_attempt do |format|
      format.html do
        if ! @mi_attempt.valid?
          flash.now[:alert] = 'Micro-injection could not be updated - please check the values you entered'
        end
        set_centres_and_consortia
        render :action => :show
      end
    end
  end

  protected

  def set_centres_and_consortia
    @centres = Centre.all
    @consortia = Consortium.all
  end

end
