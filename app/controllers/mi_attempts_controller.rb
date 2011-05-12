class MiAttemptsController < ApplicationController

  # TODO before_filter :authenticate, :only => :index

  def index
    @search_params = {
      :search_terms => []
    }

    if !params[:search_terms].blank?
      @search_params[:search_terms] = params[:search_terms].lines.collect(&:strip)
    end

    if !params[:production_centre_id].blank?
      @search_params[:production_centre_id] = params[:production_centre_id].to_i
    end
  end
end
