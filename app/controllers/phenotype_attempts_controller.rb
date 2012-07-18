# encoding: utf-8

class PhenotypeAttemptsController < ApplicationController

  respond_to :html, :json, :xml

  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html do
        set_centres_consortia_and_strains
        q = params[:q] ||= {}

        q[:terms] ||= ''
        q[:terms] = q[:terms].lines.map(&:strip).select{|i|!i.blank?}.join("\n")
      end

      format.xml { render :xml => data_for_serialized(:xml).to_xml(:root => 'phenotype_attempts', :dasherize => false) }
      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def data_for_serialized(format)
    super(format, 'id asc', Public::PhenotypeAttempt, :public_search)
  end
  protected :data_for_serialized

  def new
    set_centres_consortia_and_strains
    @user = current_user
    @mi_attempt = MiAttempt.find_by_id(params[:mi_attempt_id])
    if @mi_attempt.status == "Genotype confirmed"
        @phenotype_attempt = Public::PhenotypeAttempt.new(
          :mi_attempt_colony_name => @mi_attempt.colony_name,
          :consortium_name => @mi_attempt.consortium_name,
          :production_centre_name => @mi_attempt.production_centre_name
        )
    else
         flash.now[:alert] = "#{@mi_attempt.status} status"
    end
  end

  def create
    #set_centres_consortia_and_strains
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

    else
      @phenotype_attempt.save!
      flash[:notice] = 'Phenotype attempt created'
    end

    respond_with @phenotype_attempt
  end

  def update
    phenotype_attempt = Public::PhenotypeAttempt.find(params[:id])
    phenotype_attempt.update_attributes(params[:phenotype_attempt])
    respond_with phenotype_attempt
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

  private

  def set_centres_consortia_and_strains
    @centres = Centre.all
    @consortia = Consortium.all
    @deleter_strain = DeleterStrain.all
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
