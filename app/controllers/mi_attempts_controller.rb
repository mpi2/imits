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
    super(format, 'id asc', Public::MiAttempt, :public_search, true)
  end
  protected :data_for_serialized

  def set_up_new
    @parms_for_es_cell_pipeline = {}
    @parms_for_crispr_pipeline = {}
  end

  def new

    if params[:set_up] || true
      @strategy = params[:strategy]
      @parms_for_crispr_pipeline =  params[:strategy] == 'crispr' ? params.dup : {}
      @parms_for_es_cell_pipeline =  params[:strategy] == 'es_cell' ? params.dup : {}

      consortium_name = params['consortium']
      production_centre_name = params['production_centre']
      gene_list = params['gene_list'].lines.map(&:strip).select{|i|!i.blank?}.map{|a| a.upcase}

      if consortium_name.blank? || production_centre_name.blank? || gene_list.blank?
        flash.now[:alert] = "Micro-injection Set up details are incomplete - please enter a value for the 'Consortium', 'Production Centre' and 'Gene List'"
        render :set_up_new
      else
        mi_plans = MiPlan.joins(:consortium, :production_centre, :gene).where("UPPER(centres.name) = '#{production_centre_name.upcase}' AND UPPER(consortia.name) = '#{consortium_name.upcase}' AND UPPER(genes.marker_symbol) IN ('#{gene_list.join("','")}') AND mi_plans.mutagenesis_via_crispr_cas9 = #{params[:strategy] == 'crispr' ? 'true' : 'false'} AND mi_plans.phenotype_only = false AND is_active = true")
        if mi_plans.map{|p| p.gene.marker_symbol}.uniq.length != gene_list.length
          flash.now[:alert] = "Cannot proceed due to missing Mi Plans. Please create #{params[:strategy] == 'crispr' ? 'a CRISPR' : 'an ES Cell'} MI Plans for the following genes before continuing #{gene_list - mi_plans.map{|mp| mp.gene.marker_symbol.upcase }}"
          render :set_up_new
        else
          # if set up is valid new form will be renderd with these expected global variables
          if params[:strategy] == 'crispr'
            gene_targets = []
            i=0
            mi_plans.each{|plan| gene_targets << GeneTarget.new(mi_plan_id: plan.id).attributes}
            puts "GENE TARGETS: #{gene_targets}"
            gene_targets.each{|gt| gt["mutagenesis_factors_attributes"] = [{"external_ref" => nil}] }
            @mi_attempt = Public::MiAttempt.new( :gene_targets_attributes => gene_targets,
                                                 :marker_symbols => mi_plans.map{|plan| plan.marker_symbol},
                                                 :consortium_name => mi_plans.first.consortium_name,
                                                 :production_centre_name => mi_plans.first.production_centre_name
                                              )
          else
            @mi_attempt = Public::MiAttempt.new(:mi_plans_ids => mi_plans.map{|plan| plan.id},
                                                :marker_symbols => mi_plans.map{|plan| plan.marker_symbol},
                                                :consortium_name => mi_plans.first.consortium_name,
                                                :production_centre_name => mi_plans.first.production_centre_name
                                              )
          end
          @vector_option = []
        end
      end
    end


  end

  def create
    use_crispr_group_id

    @mi_attempt = Public::MiAttempt.new(params[:mi_attempt])
    @mi_attempt.updated_by = current_user
    return unless authorize_user_production_centre(@mi_attempt)
    return if empty_payload?(params[:mi_attempt])
    get_marker_symbol
    @vector_options = get_vector_options(@marker_symbol)
    if params.has_key?(:crispr_group_load_error) && ! params[:crispr_group_load_error].blank?
      flash.now[:alert] = "Micro-injection could not be created - please check the values you entered"
      flash.now[:alert] += "<br/> #{params[:crispr_group_load_error]}"
      @mi_attempt.errors.add(:group, params[:crispr_group_load_error])
    elsif ! @mi_attempt.valid?
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

    get_marker_symbol
    @vector_options = get_vector_options(@marker_symbol)
    respond_with @mi_attempt
  end

  def update
    # TODO: put this somewhere more sensible
    Paperclip.options[:content_type_mappings] = { scf: 'application/octet-stream' }

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
        # temp fix for when update fails silently (mi_plan status change problem eg. mi_attempt 12165)
        if ! @mi_attempt.mi_plan.valid?
          flash.now[:notice] = nil
          flash.now[:alert] = @mi_attempt.mi_plan.errors.full_messages.first
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
      elsif tv.type =='TargRep::HdrAllele'
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

  def use_crispr_group_id
    return if ! params.has_key?(:mi_attempt)
    if params.has_key?(:create_from_cripr_group_id) and params[:create_from_cripr_group_id] == true
      grab_crispr_group_data
      return true
    end
    return false
  end
  private :use_crispr_group_id

  def grab_crispr_group_data
    params[:crispr_group_load_error] = "group_id required" if !params.has_key?(:group_id)
    params[:crispr_group_load_error] = "Invalid group_id. Must be an integer" if params[:group_id].to_i == 0

    if !params.has_key?(:crispr_group_load_error)
      crispr_group = TargRep::Lims2CrisprGroup.find_by_group_id(params[:group_id].to_i)
      if !crispr_group.errors.blank?
        params[:crispr_group_load_error] = crispr_group.errors
      else
        params[:mi_attempt][:mutagenesis_factor_attributes] = {}
        i=0
        params[:mi_attempt][:mutagenesis_factor_attributes][:crisprs_attributes] = {}
        crispr_group.crispr_list.each do |crispr|
          params[:mi_attempt][:mutagenesis_factor_attributes][:crisprs_attributes][i] = crispr
          i += 1
        end
        i=0
        params[:mi_attempt][:mutagenesis_factor_attributes][:genotype_primers_attributes] = {}
        crispr_group.genotype_primer_list.each do |genotype_primer|
          params[:mi_attempt][:mutagenesis_factor_attributes][:genotype_primers_attributes][i] = genotype_primer
          i += 1
        end
      end
    end
  end
  private :grab_crispr_group_data

end
