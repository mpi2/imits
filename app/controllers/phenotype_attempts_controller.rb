# encoding: utf-8

class PhenotypeAttemptsController < ApplicationController

  respond_to :json

  before_filter :authenticate_user!

  def show
    phenotype_attempt = Public::PhenotypeAttempt.find_by_id(params[:id])
    respond_with phenotype_attempt
  end

  def create
    phenotype_attempt = Public::PhenotypeAttempt.create(params[:phenotype_attempt])
    respond_with phenotype_attempt
  end

  def update
    phenotype_attempt = Public::PhenotypeAttempt.find_by_id(params[:id])
    phenotype_attempt.update_attributes(params[:phenotype_attempt])
    respond_with phenotype_attempt
  end

  protected

  def public_phenotype_attempt_url(id)
    mi_plan_url(id)
  end

end
