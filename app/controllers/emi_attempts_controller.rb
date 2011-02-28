class EmiAttemptsController < ApplicationController
  def index
    if !params[:search_terms].blank?
      @search_terms = params[:search_terms].lines.collect(&:strip)
    end
  end
end
