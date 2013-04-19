# encoding: utf-8

class Open::PhenotypeAttemptsController < ApplicationController

  respond_to :html

  def index
    respond_to do |format|
      set_centres_and_consortia
      format.html do
        q = params[:q] ||= {}

        q[:terms] ||= ''
        q[:terms] = q[:terms].lines.map(&:strip).select{|i|!i.blank?}.join("\n")
        @access = false
        render 'phenotype_attempts/index' # renders the apps/views/phenotype_attempts/index.html.erb view.
      end
    end
  end

  def show
    @phenotype_attempt = Public::PhenotypeAttempt.find(params[:id])
    @mi_attempt = @phenotype_attempt.mi_attempt
    respond_with @phenotype_attempt
  end

end
