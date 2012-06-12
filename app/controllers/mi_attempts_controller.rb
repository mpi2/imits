# encoding: utf-8

class MiAttemptsController < ApplicationController

  respond_to :html, :json, :xml

  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html do
        set_centres_and_consortia
        q = params[:q] ||= {}

        q[:terms] ||= ''
        q[:terms] = q[:terms].lines.map(&:strip).select{|i|!i.blank?}.join("\n")
      end

      format.xml { render :xml => data_for_serialized(:xml).to_xml(:root => 'mi_attempts', :dasherize => false) }
      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def data_for_serialized(format)
    super(format, 'id asc', Public::MiAttempt, :public_search)
  end
  protected :data_for_serialized

  def new
    set_centres_and_consortia

    @mi_attempt = Public::MiAttempt.new(
      :production_centre_name => current_user.production_centre.name
    )
  end

  def create
    @mi_attempt = Public::MiAttempt.new(params[:mi_attempt])
    @mi_attempt.updated_by = current_user
    @mi_attempt.production_centre_name ||= current_user.production_centre.name

    return unless authorize_user_production_centre

    if ! @mi_attempt.valid?
      flash.now[:alert] = 'Micro-injection could not be created - please check the values you entered'
      if ! @mi_attempt.errors[:base].blank?
        flash.now[:alert] += '<br/>' + @mi_attempt.errors[:base].join('<br/>')
      end
      set_centres_and_consortia
    elsif request.format == :html and
              params[:ignore_warnings] != 'true' and
              @mi_attempt.generate_warnings
      set_centres_and_consortia
      render :action => :new
      return
    else
      @mi_attempt.save!
      flash[:notice] = 'Micro-injection attempt created'
    end

    respond_with @mi_attempt
  end

  def show
    set_centres_and_consortia
    @mi_attempt = Public::MiAttempt.find(params[:id])
    if @mi_attempt.status == 'Genotype confirmed' && @mi_attempt.distribution_centres.length == 0
      @mi_attempt.distribution_centres.build
    end

    respond_with @mi_attempt
  end

  def update
    @mi_attempt = Public::MiAttempt.find(params[:id])
    @mi_attempt.attributes = params[:mi_attempt]
    @mi_attempt.updated_by = current_user

    return unless authorize_user_production_centre

    if @mi_attempt.save
      @mi_attempt.reload
      flash.now[:notice] = 'MI attempt updated successfully'
    end

    respond_with @mi_attempt do |format|
      format.html do
        if ! @mi_attempt.valid?
          flash.now[:alert] = 'Micro-injection could not be updated - please check the values you entered'
        end
        set_centres_and_consortia
        render :action => :show
      end

      if @mi_attempt.valid?
        format.json do
          if params[:extended_response].to_s == 'true'
            render :json => json_format_extended_response(@mi_attempt, 1)
          else
            render :json => @mi_attempt
          end
        end
      end
    end
  end

  def history
    @resource = MiAttempt.find(params[:id])
    render :template => '/shared/history'
  end

  private

  def set_centres_and_consortia
    @centres = Centre.all
    @consortia = Consortium.all
  end

  def authorize_user_production_centre
    return true unless request.format == :json

    if current_user.production_centre.name != @mi_attempt.production_centre_name
      render :json => {
        'error' => 'Cannot create/update MI attempts for other production centres'
      }, :status => 401
      return false
    end

    return true
  end

  alias_method :public_mi_attempt_url, :mi_attempt_url
  helper do
    def public_mi_attempts_path(*args); mi_attempts_path(*args); end
    def public_mi_attempt_path(*args); mi_attempt_path(*args); end
  end

end
