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

  def create
    render :json => {
      'error' => 'Mi_attempts cannot be created or modified in iMits anymore. Please visit the new tracking system webpage www.gentar.org/tracker/'
    }, :status => 401
    return true
  end

  def show
    @mi_attempt = Public::MiAttempt.find(params[:id])

    get_marker_symbol
    @vector_options = get_vector_options(@marker_symbol)
    respond_with @mi_attempt
  end

  def update
    render :json => {
      'error' => 'Mi_attempts cannot be created or modified in iMits anymore. Please visit the new tracking system webpage www.gentar.org/tracker/'
    }, :status => 401
    return true
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
    return {values: [], disabled: []} if marker_symbol.blank?

    gene = Gene.find_by_marker_symbol(marker_symbol)
    if gene.nil?
      gene = Gene.find(:first, :conditions => ["lower(marker_symbol) = ?", marker_symbol.downcase])
    end
    return [] if gene.nil?

    values = ["", "-- CRISPR --", ["Targeted Vector"], "-- ES CELL --", ["Targeted Vector"]]

    gene.vectors.each do |tv|
      if tv.type =='TargRep::CrisprTargetedAllele'
        values[2] << tv.name
      elsif tv.type =='TargRep::TargetedAllele'
        values[4] << tv.name
      end
    end

    options = {values: values.flatten, disabled: ["Targeted Vector", "Oligo", "-- CRISPR --", "-- ES CELL --"]}
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

  def process_params
    mi = Public::MiAttempt.find(params[:id]) if params.has_key?(:id)
    return if mi.es_cell_name.blank? && (!params.has_key(:es_cell_name) || params[:es_cell_name].blank?)
    mutagenesis_factor_id = mi.blank? ? nil : mi.mutagenesis_factor.try(:id)
    colony_id = mi.blank? || mi.colonies.blank? ? nil : mi.colonies.first.try(:id) 
    allele_id = mi.blank? || mi.colonies.blank? || mi.colonies.first.alleles.blank? ? nil : mi.colonies.first.alleles.first.try(:id) 

    # MUTAGENESIS FACTOR ATTRIBUTES
    if params.has_key?(:es_cell_name)
#      params[:mutagenesis_factor_attributes] = {} unless params.has_key?(:mutagenesis_factor_attributes)
#      params[:mutagenesis_factor_attributes][:id] = mutagenesis_factor_id unless   params[:mutagenesis_factor_attributes].has_key(:id) || mutagenesis_factor_id.blank?
#      params[:mutagenesis_factor_attributes][:es_cell_name] = params[:es_cell_name]
    end

    # COLONIES ATTRIBUTES
    if params.has_key?(:external_ref) || params.has_key?(:colony_name) || params.has_key?(:background_strain_name) || params.has_key?(:distribution_centres_attributes) || params.has_key(:mouse_allele_type) || params_has_production_qc_param?
      params[:colonies_attributes] = {} unless params.has_key?(:colonies_attributes)
      params[:colonies_attributes][:id] = colony_id unless params[:colonies_attributes].has_key(:id) || colony_id.blank?

      params[:colonies_attributes][:name] = params[:colony_name] if params.has_key?(:colony_name)
      params[:colonies_attributes][:name] = params[:external_ref] if params.has_key?(:external_ref)
      params[:colonies_attributes][:background_strain_name] = params[:background_strain_name] if params.has_key?(:background_strain_name)
      params[:colonies_attributes][:distribution_centres_attributes] = params[:distribution_centres_attributes] if params.has_key?(:distribution_centres_attributes)

      # ALLELE ATTRIBUTES
      if params.has_key(:mouse_allele_type) || params_has_production_qc_param?
        params[:colonies_attributes][:alleles_attributes] = {} unless params.has_key?(:alleles_attributes)
        params[:colonies_attributes][:alleles_attributes][:id] = allele_id unless params[:colonies_attributes][:alleles_attributes].has_key(:id) || allele_id.blank?

        params[:colonies_attributes][:alleles_attributes][:allele_type] = params[:mouse_allele_type] if params.has_key?(:mouse_allele_type)

        # PRODUCTION QC ATTRUBUTES
        params[:colonies_attributes][:alleles_attributes][:southern_blot] = params[:qc_southern_blot_result] if params.has_key?(:qc_southern_blot_result)
        params[:colonies_attributes][:alleles_attributes][:five_prime_lr_pcr] = params[:qc_five_prime_lr_pcr_result] if params.has_keys?(:qc_five_prime_lr_pcr_result)
        params[:colonies_attributes][:alleles_attributes][:five_prime_cassette_integrity] = params[:qc_five_prime_cassette_integrity_result] if params.has_keys?(:qc_five_prime_cassette_integrity_result)
        params[:colonies_attributes][:alleles_attributes][:tv_backbone_assay] = params[:qc_tv_backbone_assay_result] if params.has_keys?(:qc_tv_backbone_assay_result)
        params[:colonies_attributes][:alleles_attributes][:neo_count_qpcr] = params[:qc_neo_count_qpcr_result] if params.has_keys?(:qc_neo_count_qpcr_result)
        params[:colonies_attributes][:alleles_attributes][:lacz_count_qpcr] = params[:qc_lacz_count_qpcr_result] if params.has_keys?(:qc_lacz_count_qpcr_result)
        params[:colonies_attributes][:alleles_attributes][:neo_sr_pcr] = params[:qc_neo_sr_pcr_result] if params.has_keys?(:qc_neo_sr_pcr_result)
        params[:colonies_attributes][:alleles_attributes][:loa_qpcr] = params[:qc_loa_qpcr_result] if params.has_keys?(:qc_loa_qpcr_result)
        params[:colonies_attributes][:alleles_attributes][:homozygous_loa_sr_pcr] = params[:qc_homozygous_loa_sr_pcr_result] if params.has_keys?(:qc_homozygous_loa_sr_pcr_result)
        params[:colonies_attributes][:alleles_attributes][:lacz_sr_pcr] = params[:qc_lacz_sr_pcr_result] if params.has_keys?(:qc_lacz_sr_pcr_result)
        params[:colonies_attributes][:alleles_attributes][:mutant_specific_sr_pcr] = params[:qc_mutant_specific_sr_pcr_result] if params.has_keys?(:qc_mutant_specific_sr_pcr_result)
        params[:colonies_attributes][:alleles_attributes][:loxp_confirmation] = params[:qc_loxp_confirmation_result] if params.has_keys?(:qc_loxp_confirmation_result)
        params[:colonies_attributes][:alleles_attributes][:three_prime_lr_pcr] = params[:qc_three_prime_lr_pcr_result] if params.has_keys?(:qc_three_prime_lr_pcr_result)
        params[:colonies_attributes][:alleles_attributes][:critical_region_qpcr] = params[:qc_critical_region_qpcr_result] if params.has_keys?(:qc_critical_region_qpcr_result)
        params[:colonies_attributes][:alleles_attributes][:loxp_srpcr] = params[:qc_loxp_srpcr_result] if params.has_keys?(:qc_loxp_srpcr_result)
        params[:colonies_attributes][:alleles_attributes][:loxp_srpcr_and_sequencing] = params[:qc_loxp_srpcr_and_sequencing_result] if params.has_keys?(:qc_loxp_srpcr_and_sequencing_result)
      end
    end
  end
  private :process_params

  def params_has_production_qc_param?
    return true unless params.select{|k, v| k.to_s =~ /qc_[\w_]+_result/ }.blank?
    return false
  end
  private :params_has_production_qc_param?

end
