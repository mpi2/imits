class MiAttemptsController < ApplicationController
  def index
    if !params[:search_terms].blank?
      @search_terms = params[:search_terms].lines.collect(&:strip)
    else
      @search_terms = []
    end
  end
end
