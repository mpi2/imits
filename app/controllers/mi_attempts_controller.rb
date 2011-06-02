class MiAttemptsController < ApplicationController

  respond_to :html

  before_filter :authenticate_user!

  def index
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

  def new
    @mi_attempt = MiAttempt.new(
      :production_centre => current_user.production_centre,
      :distribution_centre => current_user.production_centre)
    @centres = Centre.all
  end

  def create
    mi_attempt = MiAttempt.new(params[:mi_attempt])
    mi_attempt.clone = Clone.find(:first)
    mi_attempt.save!
    flash[:notice] = 'MI Attempt created'
    redirect_to root_path
  end

  def edit
    @mi_attempt = MiAttempt.find(params[:id])
  end

end
