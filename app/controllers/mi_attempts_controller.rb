# encoding: utf-8

class MiAttemptsController < ApplicationController

  respond_to :html, :json

  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html do
        authenticate_user!
        set_centres_and_consortia
        q = params[:q] ||= {}

        q[:terms] ||= ''
        q[:terms] = q[:terms].lines.map(&:strip).select{|i|!i.blank?}.join("\n")
        @access = true
      end

      format.json { render :json => data_for_serialized(:json) }
    end
  end

  def data_for_serialized(format)
    super(format, 'id asc', Public::MiAttempt, :public_search, false)
  end
  protected :data_for_serialized

  def new
    @mi_attempt = Public::MiAttempt.new
    @vector_option = []
  end

  def create
    puts "PARAMS: #{params}"
    @mi_attempt = Public::MiAttempt.new(params[:mi_attempt])
    @mi_attempt.updated_by = current_user
    return unless authorize_user_production_centre(@mi_attempt)
    return if empty_payload?(params[:mi_attempt])
    get_marker_symbol
    @vector_options = get_vector_options(@marker_symbol)
    if ! @mi_attempt.valid?
      flash.now[:alert] = "Micro-injection could not be created - please check the values you entered"

      if ! @mi_attempt.errors[:base].blank?
        flash.now[:alert] += '<br/>' + @mi_attempt.errors[:base].join('<br/>')
      end
    elsif request.format == :html and
              params[:ignore_warnings] != 'true' and
              @mi_attempt.generate_warnings
      render :action => :new
      return
    else
      if @mi_attempt.production_centre.blank?
        @mi_attempt.mi_plan.update_attributes!(:production_centre => current_user.production_centre)
      end
      @mi_attempt.save!
      flash[:notice] = 'Micro-injection attempt created'
    end

    respond_with @mi_attempt
  end

  def show
    @mi_attempt = Public::MiAttempt.find(params[:id])
    if @mi_attempt.has_status?(:gtc) && @mi_attempt.distribution_centres.length == 0
      @mi_attempt.distribution_centres.build
    end
    get_marker_symbol
    @vector_options = get_vector_options(@marker_symbol)
    respond_with @mi_attempt
  end

  def update
    @mi_attempt = Public::MiAttempt.find(params[:id])
    return unless authorize_user_production_centre(@mi_attempt)
    return if empty_payload?(params[:mi_attempt])

    @mi_attempt.updated_by = current_user

    if @mi_attempt.update_attributes(params[:mi_attempt])
      @mi_attempt.reload
      flash.now[:notice] = 'MI attempt updated successfully'
    end

    get_marker_symbol
    @vector_options = get_vector_options(@marker_symbol)

    respond_with @mi_attempt do |format|
      format.html do
        if ! @mi_attempt.valid?
          flash.now[:alert] = 'Micro-injection could not be updated - please check the values you entered'
        end
        set_centres_and_consortia
        @mi_attempt.reload
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

  alias_method :public_mi_attempt_url, :mi_attempt_url
  private :public_mi_attempt_url
  helper do
    def public_mi_attempts_path(*args); mi_attempts_path(*args); end
    def public_mi_attempt_path(*args); mi_attempt_path(*args); end
  end

  def attributes
    render :json => create_attribute_documentation_for(Public::MiAttempt)
  end

  def get_vector_options(marker_symbol)
    return {values: [], disabled: [] , selected:''} if marker_symbol.blank?

    gene = Gene.find_by_marker_symbol(marker_symbol)
    if gene.nil?
      gene = Gene.find(:first, :conditions => ["lower(marker_symbol) = ?", marker_symbol.downcase])
    end
    return [] if gene.nil?

    values = ["", "-- CRISPR --", ["Targeted Vector"], ["Oligo"], "-- ES CELL --", ["Targeted Vector"]]

    gene.vectors.each do |tv|
      if tv.type =='TargRep::CrisprTargetedAllele'
        values[2] << tv.name
      elsif tv.type =='TargRep::HrdAllele'
        values[3] << tv.name
      elsif tv.type =='TargRep::TargetedAllele'
        values[5] << tv.name
      end
    end

    options = {values: values.flatten, disabled: ["Targeted Vector", "Oligo", "-- CRISPR --", "-- ES CELL --"] , selected: @mi_attempt.mutagenesis_factor.try(:vector_name)}
    return options
  end
  private :get_vector_options


  def get_marker_symbol

    if params.has_key?(:marker_symbol) and !params[:marker_symbol].blank?
      @marker_symbol = params[:marker_symbol]
    else
      @marker_symbol = @mi_attempt.mi_plan.try(:gene).try(:marker_symbol)
    end
  end
  private :get_marker_symbol
end
