class EmiAttemptsController < ApplicationController
  def index
    if !params[:clone_names].blank?
      @clone_names = params[:clone_names].lines.collect(&:strip)
    end
  end
end
