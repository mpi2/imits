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

      format.xml { render :xml => data_for_serialized(:xml) }
      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def data_for_serialized(format)
    super(format, 'id', MiAttempt, :public_search)
  end
  protected :data_for_serialized

  def new
    set_centres_and_consortia
    @mi_attempt = MiAttempt.new(
      :production_centre_name => current_user.production_centre.name,
      :distribution_centre_name => current_user.production_centre.name
    )
  end

  def create
    @mi_attempt = MiAttempt.new(params[:mi_attempt])
    @mi_attempt.updated_by = current_user
    @mi_attempt.production_centre_name ||= current_user.production_centre.name

    if ! @mi_attempt.valid?
      flash.now[:alert] = 'Micro-injection could not be created - please check the values you entered'
      set_centres_and_consortia
    elsif request.format == :html and params[:ignore_warnings] != 'true' and @mi_attempt.generate_warnings
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
    @mi_attempt = MiAttempt.find(params[:id])
    respond_with @mi_attempt
  end

  def update
    @mi_attempt = MiAttempt.find(params[:id])
    @mi_attempt.attributes = params[:mi_attempt]
    @mi_attempt.updated_by = current_user

    if @mi_attempt.save
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
        format.json { render :json => json_format_extended_response(@mi_attempt, 1) }
      end
    end
  end

  def history
    @mi_attempt = MiAttempt.find(params[:id])
  end

  private

  def set_centres_and_consortia
    @centres = Centre.all
    @consortia = Consortium.all
  end

end
