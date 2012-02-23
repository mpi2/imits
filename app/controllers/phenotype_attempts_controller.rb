# encoding: utf-8

class PhenotypeAttemptsController < ApplicationController
  
  respond_to :html, :json, :xml

  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'id', Public::PhenotypeAttempt, :public_search)
      end
      format.html do
      end
    end
  end
  
  def new
    set_centres_and_consortia
    @user = current_user
    @mi_attempt = MiAttempt.find_by_id(params[:mi_attempt_id])
    if @mi_attempt.status == "Genotype confirmed"
        @phenotype_attempt = Public::PhenotypeAttempt.new(:mi_attempt_colony_name => @mi_attempt.colony_name)
        @phenotype_attempt.consortium_name = @mi_attempt.consortium_name
        @phenotype_attempt.production_centre_name = @mi_attempt.production_centre_name
    else
         flash.now[:alert] = "#{@mi_attempt.status} status"
    end
  end
  
  def create
    @phenotype_attempt = Public::PhenotypeAttempt.new(params[:phenotype_attempt])
    @mi_attempt = MiAttempt.find_by_colony_name(@phenotype_attempt.mi_attempt_colony_name)
    @phenotype_attempt.production_centre_name ||= current_user.production_centre.name

    return unless authorize_user_production_centre

    if ! @phenotype_attempt.valid?
      plan_error = @phenotype_attempt.errors[:mi_plan].find { |e| /cannot be found with supplied parameters/ =~ e}
      if plan_error != nil
        flash.now[:alert] = "Plan " << plan_error
      else
        flash.now[:alert] = "Phenotype attempt could not be created - please check the values you entered"
      end
      
      if ! @phenotype_attempt.errors[:base].blank?
        flash.now[:alert] += '<br/>' + @phenotype_attempt.errors[:base].join('<br/>')
      end
      set_centres_and_consortia
    else
      @phenotype_attempt.save!
      flash[:notice] = 'Phenotype attempt created'
    end

    respond_with @phenotype_attempt
  end

  def update
    phenotype_attempt = Public::PhenotypeAttempt.find_by_id(params[:id])
    phenotype_attempt.update_attributes(params[:phenotype_attempt])
    respond_with phenotype_attempt
  end
  
  def show
    phenotype_attempt = Public::PhenotypeAttempt.find_by_id(params[:id])
    respond_with phenotype_attempt
  end

  private
  
  def set_centres_and_consortia
    @centres = Centre.all
    @consortia = Consortium.all
  end
  
  def authorize_user_production_centre
    return true unless request.format == :json

    if current_user.production_centre.name != @phenotype_attempt.production_centre_name
      render :json => {
        'error' => 'Cannot create/update phenotype attempts for other production centres'
      }, :status => 401
      return false
    end

    return true
  end
  
  alias_method :public_phenotype_attempt_url, :phenotype_attempt_url
  helper do
    def public_phenotype_attempts_path(*args); phenotype_attempts_path(*args); end
    def public_phenotype_attempt_path(*args); phenotype_attempt_path(*args); end
  end

end
