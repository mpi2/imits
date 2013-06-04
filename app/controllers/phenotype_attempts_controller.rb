# encoding: utf-8

class PhenotypeAttemptsController < ApplicationController

  respond_to :html, :json

  before_filter :authenticate_user!, :except => [:index]

  def index
    respond_to do |format|
      format.html do
        authenticate_user!
        set_centres_consortia_and_strains
        q = params[:q] ||= {}

        q[:terms] ||= ''
        q[:terms] = q[:terms].lines.map(&:strip).select{|i|!i.blank?}.join("\n")
        @access = true
      end

      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def data_for_serialized(format)
    super(format, 'id asc', Public::PhenotypeAttempt, :public_search, false)
  end
  protected :data_for_serialized

  def new
    set_centres_consortia_and_strains
    @user = current_user
    @mi_attempt = MiAttempt.find_by_id(params[:mi_attempt_id])
    if @mi_attempt.status.name == "Genotype confirmed"
      @phenotype_attempt = Public::PhenotypeAttempt.new(
        :mi_plan => @mi_attempt.mi_plan
      )
    else
      flash.now[:alert] = "#{@mi_attempt.status.name} status"
    end
  end

  def create
    set_centres_consortia_and_strains
    @phenotype_attempt = Public::PhenotypeAttempt.new(params[:phenotype_attempt])
    @mi_attempt = MiAttempt.find_by_colony_name(@phenotype_attempt.mi_attempt_colony_name)

    return unless authorize_user_production_centre(@phenotype_attempt)
    return if empty_payload?(params[:phenotype_attempt])

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

    else
      @phenotype_attempt.save!
      flash[:notice] = 'Phenotype attempt created'
    end

    respond_with @phenotype_attempt
  end

  def update
    @phenotype_attempt = Public::PhenotypeAttempt.find(params[:id])

    return unless authorize_user_production_centre(@phenotype_attempt)
    return if empty_payload?(params[:phenotype_attempt])

    @phenotype_attempt.update_attributes(params[:phenotype_attempt])

    respond_with @phenotype_attempt do |format|
      format.html do
        if ! @phenotype_attempt.valid?
          flash.now[:alert] = 'Phenotype attempt could not be updated - please check the values you entered'
        else
          flash.now[:notice] = 'Phenotype attempt updated successfully'
        end
        set_centres_consortia_and_strains
        @phenotype_attempt.reload
        @mi_attempt = @phenotype_attempt.mi_attempt
        render :action => :show
      end

      format.json do
        if @phenotype_attempt.valid?
          render :json => @phenotype_attempt
        else
          render :json => @phenotype_attempt.errors, :status => :unprocessable_entity
        end
      end
    end
  end

  def show
    set_centres_consortia_and_strains
    @phenotype_attempt = Public::PhenotypeAttempt.find(params[:id])
    @mi_attempt = @phenotype_attempt.mi_attempt
    respond_with @phenotype_attempt
  end

  def history
    @resource = PhenotypeAttempt.find(params[:id])
    render :template => '/shared/history'
  end

  def set_centres_consortia_and_strains
    @centres = Centre.all
    @consortia = Consortium.all
    @deleter_strain = DeleterStrain.all
    @colony_background_strain = Strain.all
  end
  private :set_centres_consortia_and_strains

  alias_method :public_phenotype_attempt_url, :phenotype_attempt_url
  private :public_phenotype_attempt_url
  helper do
    def public_phenotype_attempts_path(*args); phenotype_attempts_path(*args); end
    def public_phenotype_attempt_path(*args); phenotype_attempt_path(*args); end
  end

  def attributes
    render :json => create_attribute_documentation_for(Public::PhenotypeAttempt)
  end

end
