# encoding: utf-8

class PhenotypeAttemptsController < ApplicationController
  respond_to :html, :only => [:index]
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

  def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'id', Public::PhenotypeAttempt, :public_search)
      end
      format.html do
      end
    end
  end

  private

  def public_phenotype_attempt_url(*args); phenotype_attempt_url(*args); end

end
