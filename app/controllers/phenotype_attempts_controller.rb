# encoding: utf-8

class PhenotypeAttemptsController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def show
    phenotype_attempt = Public::PhenotypeAttempt.find_by_id(params[:id])
    respond_with phenotype_attempt
  end

end
