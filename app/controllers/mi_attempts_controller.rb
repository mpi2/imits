class MiAttemptsController < ApplicationController

  # TODO before_filter :authenticate, :only => :index

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

end
