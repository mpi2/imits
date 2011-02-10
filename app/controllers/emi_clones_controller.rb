class EmiClonesController < ApplicationController
  def index
    if !params[:clone_names].blank?
      clone_name = params[:clone_names].lines.collect(&:chomp)
      @emi_attempts = EmiAttempt.by_clone_names(clone_name)
    end
  end
end
